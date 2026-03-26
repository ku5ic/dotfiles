local M = {}

local prompts_module = require("utils.copilotchat.prompts")

M.config = {
	include_diagnostics = true,
	include_git = false,
}

M.prompts = prompts_module.prompts

local CONTEXT_TAGS = {
	SELECTION = "#selection",
	BUFFER = "#buffer:active",
	GIT = "#git",
}

local function is_visual_mode()
	local mode = vim.fn.mode()
	return mode == "v" or mode == "V" or mode == "\22"
end

local function file_exists(path)
	return type(path) == "string" and path ~= "" and vim.fn.filereadable(path) == 1
end

local function normalize_path(path)
	return vim.fn.fnamemodify(path, ":p")
end

local function project_root()
	return normalize_path(vim.fn.getcwd())
end

local function current_buffer_path()
	local name = vim.api.nvim_buf_get_name(0)
	if not name or name == "" then
		return nil
	end
	return normalize_path(name)
end

local function path_relative_to_root(path, root)
	local escaped_root = vim.pesc(root)
	return path:gsub("^" .. escaped_root .. "/?", "")
end

local function add_unique_tag(tags, seen, tag)
	if type(tag) ~= "string" or tag == "" then
		return
	end
	if not seen[tag] then
		seen[tag] = true
		table.insert(tags, tag)
	end
end

local function collect_repo_root_docs(names)
	local tags = {}
	local root = project_root()

	for _, name in ipairs(names or {}) do
		local candidate = root .. "/" .. name
		if file_exists(candidate) then
			table.insert(tags, "#file:" .. path_relative_to_root(candidate, root))
		end
	end

	return tags
end

local function collect_upward_docs(names)
	local tags = {}
	local root = project_root()
	local buf_path = current_buffer_path()

	if not buf_path then
		return tags
	end

	local dir = vim.fn.fnamemodify(buf_path, ":p:h")
	local root_with_sep = root .. "/"

	while dir and dir ~= "" do
		for _, name in ipairs(names or {}) do
			local candidate = dir .. "/" .. name
			if file_exists(candidate) then
				table.insert(tags, "#file:" .. path_relative_to_root(candidate, root))
			end
		end

		if dir == root then
			break
		end

		if not dir:find("^" .. vim.pesc(root_with_sep)) then
			break
		end

		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end

	return tags
end

local function collect_repo_files_by_name(names)
	local tags = {}
	local root = project_root()

	for _, name in ipairs(names or {}) do
		local matches = vim.fn.globpath(root, "**/" .. name, false, true)
		for _, match in ipairs(matches) do
			local full = normalize_path(match)
			if file_exists(full) then
				table.insert(tags, "#file:" .. path_relative_to_root(full, root))
			end
		end
	end

	return tags
end

---@class CopilotChatDynamicContext
---@field repo_root_docs? string[]
---@field upward_docs? string[]
---@field repo_anywhere_docs? string[]
---@field extra? string[]
---
--- Resolve declarative dynamic context rules into concrete CopilotChat tags.
---
--- Purpose:
--- - Expand repo-aware prompt context only from files that actually exist.
--- - Support three discovery modes:
---   - `repo_root_docs`: exact files at repository root.
---   - `upward_docs`: nearest matching files walking upward from current buffer dir.
---   - `repo_anywhere_docs`: matching filenames anywhere in the repository.
---
--- Constraints / edge cases:
--- - Missing files are ignored silently.
--- - Results are deduplicated while preserving discovery order.
--- - Paths are normalized and emitted as repo-relative `#file:` tags.
---
---@param dynamic_context? CopilotChatDynamicContext
---@return string[] tags
local function resolve_dynamic_context(dynamic_context)
	local tags = {}
	local seen = {}

	if type(dynamic_context) ~= "table" then
		return tags
	end

	if type(dynamic_context.repo_root_docs) == "table" then
		for _, tag in ipairs(collect_repo_root_docs(dynamic_context.repo_root_docs)) do
			add_unique_tag(tags, seen, tag)
		end
	end

	if type(dynamic_context.upward_docs) == "table" then
		for _, tag in ipairs(collect_upward_docs(dynamic_context.upward_docs)) do
			add_unique_tag(tags, seen, tag)
		end
	end

	if type(dynamic_context.repo_anywhere_docs) == "table" then
		for _, tag in ipairs(collect_repo_files_by_name(dynamic_context.repo_anywhere_docs)) do
			add_unique_tag(tags, seen, tag)
		end
	end

	if type(dynamic_context.extra) == "table" then
		for _, tag in ipairs(dynamic_context.extra) do
			add_unique_tag(tags, seen, tag)
		end
	end

	return tags
end

---@class CopilotChatAskOptions
---@field selection_only? boolean
---@field context? string[]
---@field dynamic_context? CopilotChatDynamicContext
---@field system_prompt? string
---
---Build context tags consumed by CopilotChat.
---
---Intent:
---Keeps context inclusion policy centralized and predictable:
---  - `context` uses explicit tags as-is when provided.
---  - `dynamic_context` appends discovered repo-aware file tags that actually exist.
---  - `selection_only=true` uses `#selection` only when a visual selection is active.
---  - Otherwise falls back to `#buffer:active` to avoid sending an empty/invalid context.
---  - Optional git context is controlled globally via `M.config.include_git`.
---
---Side effects:
---None (pure builder).
---
---@param opts? CopilotChatAskOptions
---@return string[] tags Ordered list of context tags appended to the user prompt.
local function build_context_tags(opts)
	opts = opts or {}

	local tags = {}
	local seen = {}

	if opts.context and #opts.context > 0 then
		for _, tag in ipairs(opts.context) do
			add_unique_tag(tags, seen, tag)
		end
	else
		if opts.selection_only and is_visual_mode() then
			add_unique_tag(tags, seen, CONTEXT_TAGS.SELECTION)
		else
			add_unique_tag(tags, seen, CONTEXT_TAGS.BUFFER)
		end

		if M.config.include_git then
			add_unique_tag(tags, seen, CONTEXT_TAGS.GIT)
		end
	end

	if type(opts.dynamic_context) == "table" then
		for _, tag in ipairs(resolve_dynamic_context(opts.dynamic_context)) do
			add_unique_tag(tags, seen, tag)
		end
	end

	return tags
end

---Compose the final prompt payload sent to CopilotChat.
---
---Non-obvious decision:
---Context tags are serialized as plain text under a `Context:` section instead of
---passing a structured context object; this matches the current `CopilotChat.ask`
---call pattern in this module.
---
---@param user_prompt? string Free-form user instruction. `nil` becomes an empty prompt body.
---@param opts? CopilotChatAskOptions
---@return string prompt Prompt text including context directives.
local function build_prompt(user_prompt, opts)
	local tags = build_context_tags(opts)
	return string.format("%s\n\nContext:\n%s", user_prompt or "", table.concat(tags, "\n"))
end

---Send an ad-hoc prompt to CopilotChat with standardized context handling.
---
---Purpose:
---Provides a single integration point that validates plugin availability, injects
---context directives, and applies local window/system prompt options.
---
---Important side effects:
---- Requires and calls into the external `CopilotChat` plugin.
---- Opens/targets a CopilotChat window (`window.title = "CopilotChat"`).
---- Emits `vim.notify` messages on failure paths.
---
---Constraints / edge cases:
---- Returns `false` when plugin load fails or `ask` is unavailable.
---- Returns `false` if `CopilotChat.ask` throws.
---- `opts.selection_only=true` only takes effect in visual mode; otherwise buffer context is used.
---- Explicit `opts.context` overrides default buffer/selection context construction.
---- `opts.dynamic_context` appends repo-aware file context discovered at dispatch time.
---
---@param user_prompt? string User message body.
---@param opts? CopilotChatAskOptions
---@return boolean ok `true` on successful dispatch, otherwise `false`.
function M.ask(user_prompt, opts)
	local ok, mod = pcall(require, "CopilotChat")
	if not ok or type(mod.ask) ~= "function" then
		vim.notify("[CopilotChat] Plugin not loaded or 'ask' API unavailable.", vim.log.levels.ERROR)
		return false
	end

	opts = opts or {}

	local prompt = build_prompt(user_prompt, opts)

	local ask_opts = {
		window = { title = "CopilotChat" },
	}

	if opts.system_prompt then
		ask_opts.system_prompt = opts.system_prompt
	end

	local success, err = pcall(mod.ask, prompt, ask_opts)

	if not success then
		vim.notify("[CopilotChat] Failed to send prompt: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	return true
end

---Resolve a named prompt from `M.prompts` and dispatch it via `M.ask`.
---
---Purpose:
---Supports two prompt definition shapes:
---1) `string` -> treated as direct user prompt.
---2) `{ prompt = string, system_prompt = string|nil, context = string[]|nil,
---     dynamic_context = table|nil }` -> merged into ask options.
---
---Non-obvious decision:
---When table-based prompts are used, prompt-defined dispatch options override any
---caller-provided equivalents via `vim.tbl_extend("force", ...)`.
---
---Side effects:
---Same runtime side effects as `M.ask`, plus warning/error notifications for unknown
---or invalid prompt definitions.
---
---@param name string Prompt key in `M.prompts`.
---@param opts? CopilotChatAskOptions
---@return boolean ok `true` when prompt is found/valid and successfully dispatched.
function M.prompt(name, opts)
	local prompt_def = M.prompts[name]

	if not prompt_def then
		vim.notify(string.format("[CopilotChat] Unknown prompt: '%s'", name), vim.log.levels.WARN)
		return false
	end

	if type(prompt_def) == "string" then
		return M.ask(prompt_def, opts)
	end

	if type(prompt_def) == "table" and type(prompt_def.prompt) == "string" then
		---@cast prompt_def { prompt: string, system_prompt: string|nil, context: string[]|nil, dynamic_context: CopilotChatDynamicContext|nil }
		local merged_opts = vim.tbl_extend("force", opts or {}, {
			system_prompt = prompt_def.system_prompt,
			context = prompt_def.context,
			dynamic_context = prompt_def.dynamic_context,
		})
		return M.ask(prompt_def.prompt, merged_opts)
	end

	vim.notify(string.format("[CopilotChat] Invalid prompt definition for '%s'", name), vim.log.levels.ERROR)
	return false
end

return M

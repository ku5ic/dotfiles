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

---Build context tags consumed by CopilotChat.
---
---Intent:
---Keeps context inclusion policy centralized and predictable:
---  - `selection_only=true` uses `#selection` only when a visual selection is active.
---  - Otherwise falls back to `#buffer:active` to avoid sending an empty/invalid context.
---  - Optional git context is controlled globally via `M.config.include_git`.
---
---Side effects:
---None (pure builder).
---
---@param opts? { selection_only?: boolean }
---@return string[] tags Ordered list of context tags appended to the user prompt.
local function build_context_tags(opts)
	opts = opts or {}

	local tags = {}

	if opts.selection_only and is_visual_mode() then
		table.insert(tags, CONTEXT_TAGS.SELECTION)
	else
		table.insert(tags, CONTEXT_TAGS.BUFFER)
	end

	if M.config.include_git then
		table.insert(tags, CONTEXT_TAGS.GIT)
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
---@param opts? { selection_only?: boolean }
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
---
---@param user_prompt? string User message body.
---@param opts? { selection_only?: boolean, system_prompt?: string }
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
---2) `{ prompt = string, system_prompt = string|nil }` -> merged into ask options.
---
---Non-obvious decision:
---When table-based prompts are used, `system_prompt` from the prompt definition
---overrides any caller-provided `opts.system_prompt` via `vim.tbl_extend("force", ...)`.
---
---Side effects:
---Same runtime side effects as `M.ask`, plus warning/error notifications for unknown
---or invalid prompt definitions.
---
---@param name string Prompt key in `M.prompts`.
---@param opts? { selection_only?: boolean, system_prompt?: string }
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
		local merged_opts = vim.tbl_extend("force", opts or {}, {
			system_prompt = prompt_def.system_prompt,
		})
		return M.ask(prompt_def.prompt, merged_opts)
	end

	vim.notify(string.format("[CopilotChat] Invalid prompt definition for '%s'", name), vim.log.levels.ERROR)
	return false
end

return M

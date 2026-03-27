local M = {}

--[[
CopilotChat Neovim utility module

Purpose:
- Provides helper functions and prompt composition for integrating with the CopilotChat Neovim plugin.
- Builds context-aware prompts for AI code assistance, including buffer, selection, git, and project documentation context.
- Supports dynamic context resolution for project-level and file-level documentation.
- Exposes a simple API for sending prompts and using named prompt templates.

Key Concepts:
- Context tags: Strings like "#selection", "#buffer:active", "#file:README.md" that instruct CopilotChat what context to include.
- Dynamic context: Allows prompts to reference project docs (e.g. README.md), upward docs (e.g. nearest package.json), or arbitrary files by name.
- Prompt templates: Predefined prompts (see `utils.copilotchat.prompts`) that can be invoked by name.

Usage:
  local copilotchat = require("utils.copilotchat")
  copilotchat.ask("Explain this code", { selection_only = true })
  copilotchat.prompt("summarize", { dynamic_context = { repo_root_docs = { "README.md" } } })

See also:
- utils/copilotchat/prompts.lua for prompt definitions.
- CLAUDE.md for Neovim architecture and keymap conventions.

--]]

local prompts_module = require("utils.copilotchat.prompts")

local uv = vim.uv or vim.loop

-- Session cache: automatically invalidated when the working directory changes.
local _cache = {}
local _cache_cwd = nil

local function cache_get(key)
	local cwd = vim.fn.getcwd()
	if cwd ~= _cache_cwd then
		_cache = {}
		_cache_cwd = cwd
	end
	return _cache[key]
end

local function cache_set(key, value)
	_cache[key] = value
	return value
end

local function make_key(...)
	return table.concat({ ... }, "\0")
end

-- Lazily detect whether `fd` is available on PATH.
local _has_fd = nil
local function has_fd()
	if _has_fd == nil then
		_has_fd = vim.fn.executable("fd") == 1
	end
	return _has_fd
end

--- Module configuration.
-- @field include_diagnostics (boolean) If true, include diagnostics in context (not currently used).
-- @field include_git (boolean) If true, include git context tag.
M.config = {
	include_diagnostics = true,
	include_git = false,
}

--- Table of named prompt templates (see prompts.lua).
M.prompts = prompts_module.prompts

local CONTEXT_TAGS = {
	SELECTION = "#selection",
	BUFFER = "#buffer:active",
	GIT = "#git",
}

--- Returns true if the current mode is any visual mode.
local function is_visual_mode()
	local mode = vim.fn.mode()
	return mode == "v" or mode == "V" or mode == "\22"
end

--- Returns true if the given file path exists and is a regular file.
-- Uses vim.uv.fs_stat (a direct libuv call) instead of vim.fn.filereadable
-- to avoid the Vimscript overhead on hot paths.
local function file_exists(path)
	if type(path) ~= "string" or path == "" then
		return false
	end
	local stat = (uv and uv.fs_stat) and uv.fs_stat(path) or nil
	return stat ~= nil and stat.type == "file"
end

--- Returns the absolute, normalized path for a given file.
local function normalize_path(path)
	return vim.fn.fnamemodify(path, ":p")
end

--- Returns the absolute path to the current working directory (project root).
local function project_root()
	return normalize_path(vim.fn.getcwd())
end

--- Returns the absolute path to the current buffer, or nil if not a file buffer.
local function current_buffer_path()
	local name = vim.api.nvim_buf_get_name(0)
	if not name or name == "" then
		return nil
	end
	return normalize_path(name)
end

--- Returns the path relative to the given root directory.
local function path_relative_to_root(path, root)
	local escaped_root = vim.pesc(root)
	return path:gsub("^" .. escaped_root .. "/?", "")
end

--- Adds a tag to the tags list if not already present.
local function add_unique_tag(tags, seen, tag)
	if type(tag) ~= "string" or tag == "" then
		return
	end
	if not seen[tag] then
		seen[tag] = true
		table.insert(tags, tag)
	end
end

--- Collects tags for documentation files at the project root.
-- @param names (table) List of filenames to check at project root.
-- @return table of context tags for found files.
local function collect_repo_root_docs(names)
	local root = project_root()
	local key = make_key("root_docs", root, table.concat(names or {}, "|"))
	local cached = cache_get(key)
	if cached then
		return cached
	end

	local tags = {}
	for _, name in ipairs(names or {}) do
		local candidate = root .. "/" .. name
		if file_exists(candidate) then
			table.insert(tags, "#file:" .. path_relative_to_root(candidate, root))
		end
	end

	return cache_set(key, tags)
end

--- Collects tags for documentation files found by walking upward from the current buffer's directory.
-- Stops at project root.
-- @param names (table) List of filenames to search for in each parent directory.
-- @return table of context tags for found files.
local function collect_upward_docs(names)
	local root = project_root()
	local buf_path = current_buffer_path()
	local key = make_key("upward_docs", root, buf_path or "", table.concat(names or {}, "|"))
	local cached = cache_get(key)
	if cached then
		return cached
	end

	local tags = {}

	if not buf_path then
		return cache_set(key, tags)
	end

	local dir = vim.fn.fnamemodify(buf_path, ":p:h")
	local root_with_sep = root .. "/"

	-- Traverse upward from the buffer's directory to the project root.
	while dir and dir ~= "" do
		for _, name in ipairs(names or {}) do
			local candidate = dir .. "/" .. name
			if file_exists(candidate) then
				table.insert(tags, "#file:" .. path_relative_to_root(candidate, root))
			end
		end

		-- Stop if we've reached the project root directory.
		if dir == root then
			break
		end

		-- Prevent escaping the project root (handles symlinks and odd cases).
		-- This ensures we never traverse above the root directory.
		if not vim.startswith(dir .. "/", root_with_sep) then
			break
		end

		-- Move up one directory.
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end

	return cache_set(key, tags)
end

--- Collects tags for all files matching given names anywhere in the repo.
-- Uses `fd` when available (much faster on large trees); falls back to globpath.
-- @param names (table) List of filenames to search for recursively.
-- @return table of context tags for found files.
local function collect_repo_files_by_name(names)
	local root = project_root()
	local key = make_key("repo_files", root, table.concat(names or {}, "|"))
	local cached = cache_get(key)
	if cached then
		return cached
	end

	local tags = {}

	for _, name in ipairs(names or {}) do
		local matches

		if has_fd() then
			matches = vim.fn.systemlist(
				string.format("fd --type f --name %s %s", vim.fn.shellescape(name), vim.fn.shellescape(root))
			)
			if vim.v.shell_error ~= 0 then
				matches = vim.fn.globpath(root, "**/" .. name, false, true)
			end
		else
			matches = vim.fn.globpath(root, "**/" .. name, false, true)
		end

		for _, match in ipairs(matches) do
			local full = normalize_path(match)
			if file_exists(full) then
				table.insert(tags, "#file:" .. path_relative_to_root(full, root))
			end
		end
	end

	return cache_set(key, tags)
end

--- Resolves dynamic context specification to a list of context tags.
-- @param dynamic_context (table) Table with keys:
--   repo_root_docs: list of filenames at repo root
--   upward_docs: list of filenames to search upward from buffer
--   repo_anywhere_docs: list of filenames to search anywhere in repo
--   extra: list of additional tags
-- @return table of unique context tags
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

--- Builds a list of context tags for a prompt.
-- @param opts (table) Options:
--   context: explicit list of tags (overrides default selection/buffer/git)
--   selection_only: if true, prefer #selection if in visual mode
--   dynamic_context: table, see resolve_dynamic_context
-- @return table of unique context tags
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

--- Builds the final prompt string with context tags.
-- @param user_prompt (string) The main user prompt.
-- @param opts (table) Options for context (see build_context_tags).
-- @return string Prompt with context section.
local function build_prompt(user_prompt, opts)
	local tags = build_context_tags(opts)
	return string.format("%s\n\nContext:\n%s", user_prompt or "", table.concat(tags, "\n"))
end

--- Sends a prompt to CopilotChat.
-- @param user_prompt (string) The main user prompt.
-- @param opts (table) Options:
--   system_prompt: string, optional system prompt for CopilotChat
--   context: list of context tags
--   dynamic_context: table, see resolve_dynamic_context
--   selection_only: boolean, prefer #selection if in visual mode
-- @return boolean True if sent successfully, false on error.
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

--- Sends a named prompt template to CopilotChat.
-- @param name (string) Name of the prompt template (see M.prompts).
-- @param opts (table) Options to override or extend the prompt definition.
-- @return boolean True if sent successfully, false on error.
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
		---@cast prompt_def { prompt: string, system_prompt: string|nil, context: string[]|nil, dynamic_context: table|nil }
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

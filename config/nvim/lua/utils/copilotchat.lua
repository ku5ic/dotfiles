local M = {}

local prompts_module = require("utils.copilotchat.prompts")

-- Configuration
-- include_diagnostics: when true, append diagnostics context tag to every request.
-- include_git: when true, append git context tag to every request.
M.config = {
	include_diagnostics = true,
	include_git = false,
}

-- Re-export prompts so plugins/copilot.lua can import them from this module
-- without needing to know about the internal submodule path.
M.prompts = prompts_module.prompts

local CONTEXT_TAGS = {
	SELECTION = "#selection",
	BUFFER = "#buffer:active",
	GIT = "#git",
}

-- Check if the editor is currently in a visual mode.
-- Uses vim.fn.mode() only — visualmode() retains the last visual mode
-- after returning to normal mode and is therefore unreliable here.
local function is_visual_mode()
	local mode = vim.fn.mode()
	return mode == "v" or mode == "V" or mode == "\22"
end

-- Build context tags based on current state and config.
-- @param opts table|nil Optional call options.
-- @field opts.selection_only boolean|nil If true, prefer #selection context
--   only while currently in visual mode; falls back to #buffer:active otherwise.
-- @return string[] tags Context tags consumed by CopilotChat in prompt text.
-- Notes:
-- - Always returns either selection or buffer tag (never neither).
-- - Diagnostics tag is controlled by M.config.include_diagnostics.
-- - Git tag is controlled by M.config.include_git.
local function build_context_tags(opts)
	opts = opts or {}

	local tags = {}

	if opts.selection_only and is_visual_mode() then
		table.insert(tags, CONTEXT_TAGS.SELECTION)
	else
		table.insert(tags, CONTEXT_TAGS.BUFFER)
	end

	if M.config.include_diagnostics then
		table.insert(tags, CONTEXT_TAGS.DIAGNOSTICS)
	end

	if M.config.include_git then
		table.insert(tags, CONTEXT_TAGS.GIT)
	end

	return tags
end

-- Build final CopilotChat prompt payload.
-- @param user_prompt string|nil Natural-language prompt body.
-- @param opts table|nil Forwarded to build_context_tags().
-- @return string prompt Prompt with normalized "Context:" section appended.
-- Side effects: none (pure string construction).
local function build_prompt(user_prompt, opts)
	local tags = build_context_tags(opts)
	return string.format("%s\n\nContext:\n%s", user_prompt or "", table.concat(tags, "\n"))
end

-- Send prompt to CopilotChat module API.
-- @param user_prompt string|nil Prompt text to send.
-- @param opts table|nil Options used for context-tag selection.
-- @return boolean ok True on successful dispatch, false on any failure.
-- Side effects:
-- - Emits vim.notify error messages for unavailable plugin API or dispatch errors.
-- - Opens/updates CopilotChat UI via mod.ask(...).
-- Constraints:
-- - Requires `require("CopilotChat")` to succeed and expose `ask`.
-- - Intentionally does not fallback to Ex commands; failure is explicit.
function M.ask(user_prompt, opts)
	local ok, mod = pcall(require, "CopilotChat")
	if not ok or type(mod.ask) ~= "function" then
		vim.notify("[CopilotChat] Plugin not loaded or 'ask' API unavailable.", vim.log.levels.ERROR)
		return false
	end

	local prompt = build_prompt(user_prompt, opts)
	local success, err = pcall(function()
		mod.ask(prompt, { window = { title = "CopilotChat" } })
	end)

	if not success then
		vim.notify("[CopilotChat] Failed to send prompt: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	return true
end

-- Resolve and execute a named canned prompt.
-- @param name string Prompt key in M.prompts.
-- @param opts table|nil Forwarded to M.ask().
-- @return boolean ok False when prompt name is unknown or dispatch fails.
-- Side effects:
-- - Warns via vim.notify if `name` is not defined in prompts table.
function M.prompt(name, opts)
	local prompt_text = M.prompts[name]

	if not prompt_text then
		vim.notify(string.format("[CopilotChat] Unknown prompt: '%s'", name), vim.log.levels.WARN)
		return false
	end

	return M.ask(prompt_text, opts)
end

return M

local M = {}

local prompts_module = require("utils.copilotchat.prompts")

-- Configuration
M.config = {
	include_diagnostics = true,
	include_git = false,
}

-- Re-export prompts so plugins/copilot.lua can import them from this module
-- without needing to know about the internal submodule path.
M.prompts = prompts_module.prompts

local CONTEXT_TAGS = {
	SELECTION = "#selection",
	BUFFER = "#buffer",
	DIAGNOSTICS = "#diagnostics",
	GIT = "#git",
}

-- Check if the editor is currently in a visual mode.
-- Uses vim.fn.mode() only — visualmode() retains the last visual mode
-- after returning to normal mode and is therefore unreliable here.
local function is_visual_mode()
	local mode = vim.fn.mode()
	return mode == "v" or mode == "V" or mode == "\22"
end

-- Build context tags based on current state and config
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

-- Build complete prompt string with context tags appended
local function build_prompt(user_prompt, opts)
	local tags = build_context_tags(opts)
	return string.format("%s\n\nContext:\n%s", user_prompt or "", table.concat(tags, "\n"))
end

-- Send a prompt to CopilotChat via the module API.
-- There is no Ex command fallback: if the module is not loaded the plugin
-- is not available and failing loudly is the correct behaviour.
function M.ask(user_prompt, opts)
	local ok, mod = pcall(require, "CopilotChat")
	if not ok or type(mod.ask) ~= "function" then
		vim.notify("[CopilotChat] Plugin not loaded or 'ask' API unavailable.", vim.log.levels.ERROR)
		return false
	end

	local prompt = build_prompt(user_prompt, opts)
	local success, err = pcall(mod.ask, prompt, { window = { title = "CopilotChat" } })

	if not success then
		vim.notify("[CopilotChat] Failed to send prompt: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	return true
end

-- Execute a named prompt from the prompts library
function M.prompt(name, opts)
	local prompt_text = M.prompts[name]

	if not prompt_text then
		vim.notify(string.format("[CopilotChat] Unknown prompt: '%s'", name), vim.log.levels.WARN)
		return false
	end

	return M.ask(prompt_text, opts)
end

return M

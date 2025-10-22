local M = {}

local prompts = require("utils.copilotchat.prompts").prompts

-- Configuration
M.config = {
	include_diagnostics = true,
	include_git = false,
}

local CONTEXT_TAGS = {
	SELECTION = "#selection",
	BUFFER = "#buffer",
	DIAGNOSTICS = "#diagnostics",
	GIT = "#git",
}

-- Safely load CopilotChat module
local function safe_require()
	local ok, mod = pcall(require, "CopilotChat")
	return ok and mod or nil
end

-- Check if currently in visual mode
local function is_visual_mode()
	local mode = vim.fn.mode()
	return mode == "v" or mode == "V" or mode == "\22" or vim.fn.visualmode() ~= ""
end

-- Build context tags for the prompt
local function build_context_tags(opts)
	opts = opts or {}

	-- Add assertion or early return if config is required
	if not M.config then
		error("Configuration not initialized")
	end

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

-- Build complete prompt with context tags
local function build_prompt(user_prompt, opts)
	opts = opts or {}
	local tags = build_context_tags(opts)

	return string.format("%s\n\nContext:\n%s", user_prompt or "", table.concat(tags, "\n"))
end

-- Attempt to send prompt via module API
local function try_module_api(prompt)
	local mod = safe_require()
	if not mod or type(mod.ask) ~= "function" then
		return false
	end

	return pcall(mod.ask, prompt, { window = { title = "CopilotChat" } })
end

-- Attempt to send prompt via Ex commands (single-line only)
local function try_ex_command(prompt)
	if prompt:find("\n") then
		return false
	end

	local escaped = vim.fn.escape(prompt, [[\|"]])
	local commands = { "CopilotChat", "CopilotChatInline" }

	for _, cmd in ipairs(commands) do
		local success = pcall(function()
			vim.cmd(cmd .. " " .. escaped)
		end)
		if success then
			return true
		end
	end

	return false
end

-- Send a prompt to CopilotChat
function M.ask(user_prompt, opts)
	local prompt = build_prompt(user_prompt, opts)

	if try_module_api(prompt) or try_ex_command(prompt) then
		return true
	end

	vim.notify("[CopilotChat] Unable to send prompt. Is the plugin loaded?", vim.log.levels.ERROR)
	return false
end

-- Execute a named prompt
function M.prompt(name, opts)
	local prompt_text = prompts[name]

	if not prompt_text then
		vim.notify(string.format("[CopilotChat] Unknown prompt: %s", name), vim.log.levels.WARN)
		return false
	end

	return M.ask(prompt_text, opts)
end

return M

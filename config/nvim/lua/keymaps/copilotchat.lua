local map = vim.keymap.set
local cc = require("utils.copilotchat")

-- Generic "ask" with input
map("n", "<leader>aa", function()
	local prompt = vim.fn.input({ prompt = "CopilotChat> " })
	if prompt and prompt:gsub("%s+", "") ~= "" then
		cc.ask(prompt, { selection_only = false }) -- full buffer
	end
end, { desc = "AI: Ask", noremap = true, silent = true })

map("v", "<leader>aa", function()
	local prompt = vim.fn.input({ prompt = "CopilotChat (visual)> " })
	if prompt and prompt:gsub("%s+", "") ~= "" then
		cc.ask(prompt, { selection_only = true }) -- selection or buffer (wrapper fallback)
	end
end, { desc = "AI: Ask (visual)", noremap = true, silent = true })

-- Helper: bind both normal and visual with consistent behavior and descriptions
local function bind_prompt(name, lhs, label)
	map("n", lhs, function()
		cc.prompt(name, { selection_only = false })
	end, { desc = "AI: " .. label, noremap = true, silent = true })
	map("v", lhs, function()
		cc.prompt(name, { selection_only = true })
	end, { desc = "AI: " .. label .. " (visual)", noremap = true, silent = true })
end

-- ensure these names exist in utils.copilotchat.prompts)
bind_prompt("Explain", "<leader>ae", "Explain")
bind_prompt("Review", "<leader>ar", "Review")
bind_prompt("Tests", "<leader>at", "Generate tests")
bind_prompt("Refactor", "<leader>af", "Refactor")
bind_prompt("Fix", "<leader>ax", "Fix issues")
bind_prompt("BetterNamings", "<leader>an", "Better namings")
bind_prompt("Docs", "<leader>aD", "Write docs")
bind_prompt("WCAG", "<leader>aW", "WCAG refactor")
bind_prompt("Summarize", "<leader>as", "Summarize")
bind_prompt("Wording", "<leader>aw", "Wording")
bind_prompt("Concise", "<leader>ac", "Concise")

-- Additional AI commands (non-prompt based)
map("n", "<leader>av", "<cmd>CopilotChatToggle<cr>", { desc = "AI: Toggle chat", noremap = true, silent = true })
map("n", "<leader>am", "<cmd>CopilotChatCommit<cr>", { desc = "AI: Generate commit message", noremap = true, silent = true })
map("n", "<leader>al", "<cmd>CopilotChatReset<cr>", { desc = "AI: Clear chat history", noremap = true, silent = true })

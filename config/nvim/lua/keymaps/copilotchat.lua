local map = vim.keymap.set
local cc = require("utils.copilotchat")

--- CopilotChat keymaps.
---
--- Purpose:
--- - Define a consistent `<leader>a*` keymap namespace for CopilotChat actions.
--- - Support both free-form prompts (`cc.ask`) and named reusable prompts (`cc.prompt`).
--- - Keep normal-mode behavior focused on full-buffer context, and visual-mode behavior
---   focused on selected text when available.
---
--- Important side effects:
--- - Registers global Neovim keymaps at load time.
--- - Invokes CopilotChat commands/functions that may open/toggle chat UI, mutate chat
---   session state, and trigger network-backed AI requests.
---
--- Constraints / non-obvious details:
--- - Visual-mode mappings depend on `utils.copilotchat` fallback behavior: when visual
---   selection is unavailable, wrappers may use buffer context instead.
--- - Prompt input is whitespace-trim checked; empty or whitespace-only prompts are ignored.
--- - `bind_prompt` names must match keys defined in `utils.copilotchat.prompts`.
---
--- Example:
--- - Select code in visual mode, press `<leader>ar` to run the predefined "Review" prompt
---   against the current selection.
--- - In normal mode, press `<leader>aa` and type a custom question for full-buffer context.

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

--- Bind a named CopilotChat prompt for both normal and visual mode.
---
--- Intent:
--- - Centralize dual-mode mappings so behavior and descriptions stay aligned.
---
--- Parameters:
--- @param name string Prompt identifier expected by `cc.prompt` (must exist in prompt table).
--- @param lhs string Keymap lhs to register in both modes.
--- @param label string Human-readable label used in `desc`.
---
--- Returns:
--- - nil (registers mappings for side effects only).
---
--- Behavior:
--- - Normal mode sends full-buffer context (`selection_only = false`).
--- - Visual mode prefers selected-text context (`selection_only = true`).
local function bind_prompt(name, lhs, label)
	map("n", lhs, function()
		cc.prompt(name, { selection_only = false })
	end, { desc = "AI: " .. label, noremap = true, silent = true })
	map("v", lhs, function()
		cc.prompt(name, { selection_only = true })
	end, { desc = "AI: " .. label .. " (visual)", noremap = true, silent = true })
end

-- ensure these names exist in utils.copilotchat.prompts
bind_prompt("Explain", "<leader>ae", "Explain code")
bind_prompt("Review", "<leader>ar", "Review code")
bind_prompt("Tests", "<leader>at", "Write tests")
bind_prompt("Refactor", "<leader>af", "Refactor code")
bind_prompt("Fix", "<leader>ax", "Fix code issues")
bind_prompt("RenameForClarity", "<leader>an", "Improve naming")
bind_prompt("Docs", "<leader>aD", "Write documentation")
bind_prompt("WCAG", "<leader>aW", "Improve accessibility")
bind_prompt("Summarize", "<leader>as", "Summarize text")
bind_prompt("Wording", "<leader>aw", "Improve wording")
bind_prompt("Concise", "<leader>az", "Make concise")
bind_prompt("Commit", "<leader>ac", "Create commit message")

-- Additional AI commands (non-prompt based)
map("n", "<leader>av", "<cmd>CopilotChatToggle<cr>", { desc = "AI: Toggle chat", noremap = true, silent = true })
map("n", "<leader>al", "<cmd>CopilotChatReset<cr>", { desc = "AI: Clear chat history", noremap = true, silent = true })
map("n", "<leader>aM", "<cmd>CopilotChatModels<cr>", { desc = "AI: Select Model", noremap = true, silent = true })

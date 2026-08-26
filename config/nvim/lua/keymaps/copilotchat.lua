local map = require("keymaps.util").map
local cc = require("utils.copilotchat")

-- <leader>a* namespace for CopilotChat (<leader>A is claudecode.nvim). Generic "ask" with input
map("n", "<leader>aa", function()
  local prompt = vim.fn.input({ prompt = "CopilotChat> " })
  if prompt and prompt:gsub("%s+", "") ~= "" then
    cc.ask(prompt, { selection_only = false }) -- full buffer
  end
end, "AI: Ask")

map("v", "<leader>aa", function()
  local prompt = vim.fn.input({ prompt = "CopilotChat (visual)> " })
  if prompt and prompt:gsub("%s+", "") ~= "" then
    cc.ask(prompt, { selection_only = true }) -- selection or buffer (wrapper fallback)
  end
end, "AI: Ask (visual)")

-- Binds a named prompt (must exist in utils.copilotchat.prompts) to both normal
-- (full buffer) and visual (selection) mode under the same lhs.
local function bind_prompt(name, lhs, label)
  map("n", lhs, function()
    cc.prompt(name, { selection_only = false })
  end, "AI: " .. label)
  map("v", lhs, function()
    cc.prompt(name, { selection_only = true })
  end, "AI: " .. label .. " (visual)")
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
map("n", "<leader>av", "<cmd>CopilotChatToggle<cr>", "AI: Toggle chat")
map("n", "<leader>al", "<cmd>CopilotChatReset<cr>", "AI: Clear chat history")
map("n", "<leader>aM", "<cmd>CopilotChatModels<cr>", "AI: Select Model")

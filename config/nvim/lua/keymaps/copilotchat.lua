local map = require("keymaps.util").map
local cc = require("utils.copilotchat")

-- <leader>A* namespace for CopilotChat (<leader>a is claudecode.nvim). Generic "ask" with input
map("n", "<leader>Aa", function()
  local prompt = vim.fn.input({ prompt = "CopilotChat> " })
  if prompt and prompt:gsub("%s+", "") ~= "" then
    cc.ask(prompt, { selection_only = false }) -- full buffer
  end
end, "AI: Ask")

map("v", "<leader>Aa", function()
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
bind_prompt("Explain", "<leader>Ae", "Explain code")
bind_prompt("Review", "<leader>Ar", "Review code")
bind_prompt("Tests", "<leader>At", "Write tests")
bind_prompt("Refactor", "<leader>Af", "Refactor code")
bind_prompt("Fix", "<leader>Ax", "Fix code issues")
bind_prompt("RenameForClarity", "<leader>An", "Improve naming")
bind_prompt("Docs", "<leader>AD", "Write documentation")
bind_prompt("WCAG", "<leader>AW", "Improve accessibility")
bind_prompt("Summarize", "<leader>As", "Summarize text")
bind_prompt("Wording", "<leader>Aw", "Improve wording")
bind_prompt("Concise", "<leader>Az", "Make concise")
bind_prompt("Commit", "<leader>Ac", "Create commit message")

-- Additional AI commands (non-prompt based)
map("n", "<leader>Av", "<cmd>CopilotChatToggle<cr>", "AI: Toggle chat")
map("n", "<leader>Al", "<cmd>CopilotChatReset<cr>", "AI: Clear chat history")
map("n", "<leader>AM", "<cmd>CopilotChatModels<cr>", "AI: Select Model")

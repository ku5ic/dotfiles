return {
  -- Claude Code IDE integration (WebSocket/MCP protocol, same as the VS Code/JetBrains extensions)
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    -- `cmd` lets lazy.nvim create command stubs on a fresh start so :ClaudeCode
    -- and friends exist before any <leader>A* key is pressed.
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    -- Default upstream keymap recipe, moved to <leader>A (capital) so CopilotChat can take <leader>a.
    keys = {
      { "<leader>A", nil, desc = "Claude Code" },
      { "<leader>Ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>Af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>Ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>AC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>Am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>Ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>As", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>As",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
      },
      -- Diff management
      { "<leader>Aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>Ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
}

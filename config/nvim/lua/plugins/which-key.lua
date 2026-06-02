return {
  {
    "folke/which-key.nvim",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      local wk = require("which-key")
      wk.setup()
      wk.add({
        { "<leader>f", group = "find/file" },
        { "<leader>s", group = "search" },
        { "<leader>g", group = "git" },
        { "<leader>w", group = "window" },
        { "<leader>t", group = "tab/explorer" },
        { "<leader>b", group = "buffer" },
        { "<leader>l", group = "lsp" },
        { "<leader>lw", group = "workspace" },
        { "<leader>x", group = "diagnostics/trouble" },
        { "<leader>d", group = "debug" },
        { "<leader>a", group = "ai/copilot" },
        { "<leader>n", group = "notifications/ui" },
        { "<leader>c", group = "copy" },
        { "<leader>h", group = "harpoon" },
        { "<leader>u", group = "ui/toggles" },
        { "<leader>e", group = "explorer" },
      })
    end,
  },
}

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    version = "v1.*",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        integrations = {
          snacks = true,
        },
      })
      vim.cmd([[colorscheme catppuccin-mocha]])
    end,
  },
}

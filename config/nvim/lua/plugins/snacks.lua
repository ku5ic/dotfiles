return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      input = { enabled = true },
    },
    keys = {
      {
        "<leader>nn",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss notifications",
      },
    },
  },
}

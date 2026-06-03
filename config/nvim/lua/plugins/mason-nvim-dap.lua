return {
  -- mason.nvim integration
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      ensure_installed = {
        "js",
      },
    },
  },
}

local discovery = require("lsp.discovery")

local function setup_mason()
  require("mason").setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  })

  require("mason-lspconfig").setup({
    ensure_installed = discovery.active_server_names(),
    automatic_installation = true,
  })

  -- Stand-alone tools (formatters, linters, debuggers)
  require("mason-tool-installer").setup({
    ensure_installed = {
      "cspell",
      "eslint",
      "js-debug-adapter",
      "prettier",
      "prettierd",
      "black",
      "ruff",
      "stylelint",
      "stylua",
      "djlint",
      "shfmt",
    },
    automatic_installation = true,
  })
end

return {
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = setup_mason,
  },
}

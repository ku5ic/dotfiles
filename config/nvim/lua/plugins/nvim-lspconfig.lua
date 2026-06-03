local discovery = require("lsp.discovery")

local function configure_diagnostics()
  local icons = require("config.icons").icons.diagnostics

  vim.diagnostic.config({
    virtual_text = {
      prefix = function(d)
        local severity_names = { "Error", "Warn", "Info", "Hint" }
        return icons[severity_names[d.severity]] .. " "
      end,
      spacing = 4,
      source = true,
    },
    float = { source = true },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = icons.Error,
        [vim.diagnostic.severity.WARN] = icons.Warn,
        [vim.diagnostic.severity.INFO] = icons.Info,
        [vim.diagnostic.severity.HINT] = icons.Hint,
      },
    },
    underline = true,
    severity_sort = true,
  })
end

local function setup_lsp_servers()
  local capabilities = require("blink.cmp").get_lsp_capabilities()
  capabilities.workspace = capabilities.workspace or {}
  capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = true }

  -- Defensive: explicitly disable the inactive TS server.
  local disabled_ts_lsp = discovery.typescript_lsp == "vtsls" and "ts_ls" or "vtsls"
  vim.lsp.config(disabled_ts_lsp, { enabled = false })

  for _, name in ipairs(discovery.active_server_names()) do
    local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, discovery.get_server_settings(name))
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

local function setup_lsp_keymaps(bufnr, client)
  -- Neovim 0.10+ sets these automatically on LspAttach; do not redefine:
  --   K      -> hover
  --   grr    -> references
  --   gri    -> implementation
  --   grn    -> rename
  --   gra    -> code action
  --   grt    -> type definition
  --   grx    -> codelens run
  -- C-]      -> definition (via LSP tagfunc)
  -- gd / gD / gi are Vim built-ins and are intentionally left alone.
  vim.keymap.set("n", "<leader>lk", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })

  require("which-key").add({ { "g", buffer = bufnr, group = "goto" } })

  if client and client.server_capabilities.codeLensProvider then
    vim.lsp.codelens.enable(true, { buffer = bufnr })
    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
      group = "dotfiles_lsp_codelens",
      buffer = bufnr,
      callback = function()
        vim.lsp.codelens.enable(true, { buffer = bufnr })
      end,
    })
    vim.keymap.set({ "n", "v" }, "<leader>lc", vim.lsp.codelens.run, { buffer = bufnr, desc = "Run Codelens" })
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    priority = 1000,
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      configure_diagnostics()
      setup_lsp_servers()

      vim.api.nvim_create_augroup("dotfiles_lsp_codelens", { clear = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("dotfiles_lsp_attach", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          setup_lsp_keymaps(args.buf, client)
        end,
      })
    end,
  },
}

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

-- Single source of truth for LSP keymaps. Two categories:
--
-- 1. Neovim 0.10+ built-in goto defaults, set by core on LspAttach. We do not
--    redefine them; the which-key block below only gives them friendly labels.
--      K    -> hover              grt -> type definition
--      grr  -> references         grx -> codelens run
--      gri  -> implementation     C-] -> definition (via LSP tagfunc)
--      grn  -> rename             gd / gD / gi are Vim built-ins, left alone
--      gra  -> code action
--
-- 2. Custom buffer-local maps below. They call vim.lsp.buf.* directly, so they
--    only make sense on a buffer with an attached client.
local function setup_lsp_keymaps(bufnr, client)
  vim.keymap.set("n", "<leader>lk", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
  vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { buffer = bufnr, desc = "LSP Rename" })
  vim.keymap.set({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, { buffer = bufnr, desc = "LSP Code Action" })

  -- Code navigation, surfaced in the <leader>l menu instead of the crowded
  -- native `g` prefix. Snacks pickers give a list UI when there are multiple
  -- results and fall through to the location when there is one.
  vim.keymap.set("n", "<leader>lg", function()
    Snacks.picker.lsp_definitions()
  end, { buffer = bufnr, desc = "Go to definition" })
  vim.keymap.set("n", "<leader>lu", function()
    Snacks.picker.lsp_references()
  end, { buffer = bufnr, desc = "Find references" })
  vim.keymap.set("n", "<leader>lm", function()
    Snacks.picker.lsp_implementations()
  end, { buffer = bufnr, desc = "Go to implementation" })
  vim.keymap.set("n", "<leader>ly", function()
    Snacks.picker.lsp_type_definitions()
  end, { buffer = bufnr, desc = "Go to type definition" })
  vim.keymap.set("n", "<leader>ls", function()
    Snacks.picker.lsp_symbols()
  end, { buffer = bufnr, desc = "Document symbols" })

  vim.keymap.set(
    "n",
    "<leader>lwa",
    vim.lsp.buf.add_workspace_folder,
    { buffer = bufnr, desc = "LSP Add workspace folder" }
  )
  vim.keymap.set(
    "n",
    "<leader>lwr",
    vim.lsp.buf.remove_workspace_folder,
    { buffer = bufnr, desc = "LSP Remove workspace folder" }
  )
  vim.keymap.set("n", "<leader>lwl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, { buffer = bufnr, desc = "LSP List workspace folders" })

  -- Description-only overlays: label the built-in goto defaults in which-key
  -- without creating or overriding the actual mappings.
  require("which-key").add({
    { "g", buffer = bufnr, group = "goto" },
    { "K", desc = "Hover documentation", buffer = bufnr },
    { "grr", desc = "References", buffer = bufnr },
    { "gri", desc = "Implementation", buffer = bufnr },
    { "grn", desc = "Rename", buffer = bufnr },
    { "gra", desc = "Code action", buffer = bufnr },
    { "grt", desc = "Type definition", buffer = bufnr },
    { "grx", desc = "Run codelens", buffer = bufnr },
  })

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

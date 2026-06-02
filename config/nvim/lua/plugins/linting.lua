return {
  "mfussenegger/nvim-lint",
  event = {
    "BufReadPre",
    "BufNewFile",
  },
  keys = {
    {
      "<leader>ll",
      function()
        require("lint").try_lint()
      end,
      desc = "Lint current file",
    },
  },
  config = function()
    local lint = require("lint")
    local filetypes = require("config.filetypes")

    local linters_by_ft = {
      svelte = { "eslint" },
      css = { "stylelint" },
      scss = { "stylelint" },
      sass = { "stylelint" },
    }

    for _, ft in ipairs(filetypes.JS_TS) do
      linters_by_ft[ft] = { "eslint" }
    end

    lint.linters_by_ft = linters_by_ft

    vim.list_extend(lint.linters.eslint.args, { "--no-warn-ignored" })

    lint.linters.stylelint = require("lint.util").wrap(lint.linters.stylelint, function(diagnostic)
      if diagnostic.message:find("Stylelint error, run `stylelint") then
        return nil
      end
      return diagnostic
    end)

    local function resolve_eslint(buf)
      local path = vim.api.nvim_buf_get_name(buf)
      if path == "" then
        return "eslint"
      end
      local dir = vim.fn.fnamemodify(path, ":h")
      local found = vim.fn.findfile("node_modules/.bin/eslint", dir .. ";") --[[@as string]]
      return found ~= "" and vim.fn.fnamemodify(found, ":p") or "eslint"
    end

    local lint_augroup = vim.api.nvim_create_augroup("dotfiles_lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function(args)
        lint.linters.eslint.cmd = resolve_eslint(args.buf)
        lint.try_lint()
      end,
    })
  end,
}

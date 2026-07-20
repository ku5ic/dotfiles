return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter")
        .install({
          "bash",
          "c",
          "css",
          "diff",
          "git_config",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          "graphql",
          "html",
          "htmldjango",
          "javascript",
          "jsdoc",
          "json",
          "lua",
          "luadoc",
          "luap",
          "markdown",
          "markdown_inline",
          "php",
          "phpdoc",
          "python",
          "query",
          "regex",
          "requirements",
          "ruby",
          "scss",
          "sql",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "yaml",
        })
        :wait(300000)

      -- Highlighting is not automatic on main branch - enable per filetype.
      -- Guard on a highlight query existing: a stale locally-cached parser
      -- can still attach with zero captures, which also
      -- blocks Neovim's builtin legacy syntax/*.vim fallback from loading.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("dotfiles_treesitter_highlight", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype) or vim.bo[args.buf].filetype
          if vim.treesitter.query.get(lang, "highlights") then
            pcall(vim.treesitter.start)
          end
        end,
      })
    end,
  },
}

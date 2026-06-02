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
          "tmux",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "yaml",
        })
        :wait(300000)

      -- Highlighting is not automatic on main branch - enable per filetype
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("dotfiles_treesitter_highlight", { clear = true }),
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}

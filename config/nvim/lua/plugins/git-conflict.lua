return {
  {
    "akinsho/git-conflict.nvim",
    version = "v2.1.0",
    event = "BufReadPre",
    opts = {
      -- moved off bare co/ct/cb/c0: "ct" hangs (native c+t operator-pending waits for a trailing char),
      -- and bare c* collides with change-operator combos generally. <leader>g is the existing git group.
      default_mappings = {
        ours = "<leader>go",
        theirs = "<leader>gt",
        both = "<leader>ga",
        none = "<leader>gx",
      },
      disable_diagnostics = false, -- ponytail: git-conflict.nvim v2.1.0/main calls removed vim.diagnostic.disable() on Neovim 0.11+, upstream unfixed
    },
  },
}

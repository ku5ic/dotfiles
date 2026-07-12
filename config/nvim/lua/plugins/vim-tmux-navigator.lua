return {
  -- Tmux side configured in ~/.tmux.conf.
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Tmux nav left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Tmux nav down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Tmux nav up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Tmux nav right" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Tmux nav previous" },
    },
  },
}

return {
  -- Seamless <C-hjkl> navigation between nvim windows and tmux panes (including
  -- terminal-mode buffers like claudecode.nvim's split). Tmux-side detection
  -- lives in .tmux.conf; this is the nvim-side half of the same handshake.
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      -- The plugin's own terminal-mode mappings use <C-w> as an escape prefix,
      -- which is Vim's :terminal escape, not Neovim's (<C-\><C-n>). In Neovim
      -- it leaks literal keystrokes into the job instead of switching panes.
      -- Disable its mappings and define our own below; its TmuxNavigate*
      -- commands (which do the actual work) are unaffected by this flag.
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left window/pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower window/pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper window/pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right window/pane" },
      { "<C-h>", "<C-\\><C-n><cmd>TmuxNavigateLeft<cr>", mode = "t", desc = "Go to left window/pane" },
      { "<C-j>", "<C-\\><C-n><cmd>TmuxNavigateDown<cr>", mode = "t", desc = "Go to lower window/pane" },
      { "<C-k>", "<C-\\><C-n><cmd>TmuxNavigateUp<cr>", mode = "t", desc = "Go to upper window/pane" },
      { "<C-l>", "<C-\\><C-n><cmd>TmuxNavigateRight<cr>", mode = "t", desc = "Go to right window/pane" },
    },
  },
}

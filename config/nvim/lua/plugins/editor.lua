return {
  -- search/replace in multiple files
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Search and replace",
      },
    },
    config = true,
  },

  -- git signs
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },

  {
    "folke/which-key.nvim",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      local wk = require("which-key")
      wk.setup()
      wk.add({
        { "<leader>f", group = "find/file" },
        { "<leader>s", group = "search" },
        { "<leader>g", group = "git" },
        { "<leader>w", group = "window" },
        { "<leader>t", group = "tab/explorer" },
        { "<leader>b", group = "buffer" },
        { "<leader>l", group = "lsp" },
        { "<leader>lw", group = "workspace" },
        { "<leader>x", group = "diagnostics/trouble" },
        { "<leader>d", group = "debug" },
        { "<leader>a", group = "ai/copilot" },
        { "<leader>n", group = "notifications/ui" },
        { "<leader>c", group = "copy" },
        { "<leader>h", group = "harpoon" },
        { "<leader>u", group = "ui/toggles" },
        { "<leader>e", group = "explorer" },
      })
    end,
  },

  -- todo comments
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous todo comment",
      },
    },
    config = true,
  },

  -- vim-fugitive is a Git wrapper so awesome, it should be illegal
  { "tpope/vim-fugitive" },

  -- vim-tmux-navigator: jump between vim splits and tmux panes with C-hjkl + C-\
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
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
    },
  },

  -- precognition.nvim assists with discovering motions (Both vertical and horizontal) to navigate your current buffer
  {
    "tris203/precognition.nvim",
    cmd = "Precognition",
    keys = {
      { "<leader>np", "<cmd>Precognition toggle<cr>", desc = "Toggle Precognition" },
    },
    opts = {
      startVisible = false,
      -- showBlankVirtLine = true,
      -- highlightColor = { link = "Comment" },
      -- hints = {
      --      Caret = { text = "^", prio = 2 },
      --      Dollar = { text = "$", prio = 1 },
      --      MatchingPair = { text = "%", prio = 5 },
      --      Zero = { text = "0", prio = 1 },
      --      w = { text = "w", prio = 10 },
      --      b = { text = "b", prio = 9 },
      --      e = { text = "e", prio = 8 },
      --      W = { text = "W", prio = 7 },
      --      B = { text = "B", prio = 6 },
      --      E = { text = "E", prio = 5 },
      -- },
      -- gutterHints = {
      --     G = { text = "G", prio = 10 },
      --     gg = { text = "gg", prio = 9 },
      --     PrevParagraph = { text = "{", prio = 8 },
      --     NextParagraph = { text = "}", prio = 8 },
      -- },
    },
  },
}

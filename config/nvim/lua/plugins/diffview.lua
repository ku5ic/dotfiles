return {
  {
    "sindrets/diffview.nvim",
    -- No release tags exist; pin to a specific commit for reproducibility.
    commit = "4516612fe98ff56ae0415a259ff6361a89419b0a",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    keys = {
      { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Diff view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current)" },
      { "q", "<cmd>DiffviewClose<cr>", desc = "Close diffview", ft = "DiffviewFiles" },
      { "q", "<cmd>DiffviewClose<cr>", desc = "Close diffview", ft = "DiffviewFileHistory" },
    },
    opts = {},
  },
}

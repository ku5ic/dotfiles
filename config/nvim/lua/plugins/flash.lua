return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = {
          -- Show jump labels on f/F/t/T so multi-occurrence jumps don't require ; repeats
          jump_labels = true,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
      {
        "S",
        -- Deliberately excludes "x" (visual) to preserve nvim-surround's visual S binding
        mode = { "n", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter select",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Flash remote",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Flash treesitter search",
      },
    },
  },
}

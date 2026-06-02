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
  },
}

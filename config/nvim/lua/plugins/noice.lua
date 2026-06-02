return {
  -- Highly experimental plugin that completely replaces the UI for messages, cmdline and the popupmenu.
  {
    "folke/noice.nvim",
    lazy = false,
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<leader>nl",
        function()
          require("noice").cmd("last")
        end,
        desc = "Show last message",
      },
      {
        "<leader>nH",
        function()
          require("noice").cmd("history")
        end,
        desc = "Show message history",
      },
      {
        "<leader>na",
        function()
          require("noice").cmd("all")
        end,
        desc = "Show all messages",
      },
      {
        "<leader>nd",
        function()
          require("noice").cmd("dismiss")
        end,
        desc = "Dismiss all messages",
      },
      {
        "<c-f>",
        function()
          if not require("noice.lsp").scroll(4) then
            return "<c-f>"
          end
        end,
        mode = { "i", "n", "s" },
        silent = true,
        expr = true,
        desc = "Scroll forward",
      },
      {
        "<c-b>",
        function()
          if not require("noice.lsp").scroll(-4) then
            return "<c-b>"
          end
        end,
        mode = { "i", "n", "s" },
        silent = true,
        expr = true,
        desc = "Scroll backward",
      },
      {
        "<S-Enter>",
        function()
          require("noice").redirect(vim.fn.getcmdline())
        end,
        mode = "c",
        desc = "Redirect cmdline",
      },
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
      },
      -- snacks.notifier owns vim.notify; noice handles cmdline/popupmenu/messages only
      notify = { enabled = false },
    },
  },
}

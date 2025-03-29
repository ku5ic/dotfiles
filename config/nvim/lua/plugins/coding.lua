return {
	{ "tpope/vim-rbenv" },
	{ "tpope/vim-surround" }, -- add, delete, change surroundings (it's awesome)
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"windwp/nvim-autopairs",
		config = function()
			-- Safely import required modules
			local autopairs = require("nvim-autopairs")
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")

			-- Configure autopairs with Treesitter support
			autopairs.setup({
				check_ts = true,
				ts_config = {
					lua = { "string" }, -- Exclude Lua string nodes
					javascript = { "template_string" }, -- Exclude JS template strings
					java = false, -- Disable Treesitter checks for Java
				},
			})

			-- Integrate autopairs with nvim-cmp
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},
}

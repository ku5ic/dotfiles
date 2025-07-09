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
	},
}

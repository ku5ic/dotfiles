return {
	{
		'nvim-treesitter/nvim-treesitter',
		dependencies = {
			'nvim-treesitter/nvim-treesitter-textobjects',
		},
		opts = {
			highlight = { enable = true },
			indent = { enable = true },
			context_commentstring = { enable = true, enable_autocmd = false },
			ensure_installed = {
				"bash",
				"c",
				"html",
				"javascript",
				"json",
				"lua",
				"luadoc",
				"luap",
				"markdown",
				"markdown_inline",
				"php",
				"python",
				"query",
				"regex",
				"ruby",
				"tsx",
				"typescript",
				"vim",
				"yaml",
			},
		},
		config = function(_, opts)
			pcall(require('nvim-treesitter.install').update { with_sync = true })
			require("nvim-treesitter.configs").setup(opts)
		end,
	}
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		enable = false,
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				sync_install = false,
				highlight = { enable = true },
				indent = { enable = true },
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
				},
				ensure_installed = {
					"bash",
					"c",
					"diff",
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
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			enable = false,
		},
	},
}

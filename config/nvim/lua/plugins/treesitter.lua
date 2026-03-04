return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			-- nvim-treesitter-textobjects must be listed as a proper dependency.
			-- The "enable" flag is not a valid lazy.nvim dependency field and has no effect here.
			-- Textobject behaviour is controlled via the select.enable key in configs.setup() below.
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
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
					-- Shell scripting
					"bash",

					-- Programming languages
					"c",
					"javascript",
					"lua",
					"php",
					"python",
					"htmldjango",
					"ruby",
					"tsx",
					"typescript",

					-- Markup languages
					"html",
					"json",
					"markdown",
					"markdown_inline",

					-- Styling
					"css",
					"scss", -- only once

					-- Git related
					"diff",
					"git_config",
					"git_rebase",
					"gitattributes",
					"gitcommit",
					"gitignore",

					-- Lua documentation
					"luadoc",
					"luap",

					-- Miscellaneous
					"query",
					"regex",
					"requirements",
					"sql",
					"tmux",
					"toml",
					"vim",
					"yaml",
					"jsdoc",
					"phpdoc",
				},
			})
		end,
	},

	{
		"davidmh/mdx.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
}

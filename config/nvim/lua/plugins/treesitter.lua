return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
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
					"bash", -- Bash scripting

					-- Programming languages
					"c", -- C programming language
					"javascript", -- JavaScript programming language
					"lua", -- Lua programming language
					"php", -- PHP programming language
					"python", -- Python programming language
					"htmldjango", -- Django templates
					"ruby", -- Ruby programming language
					"tsx", -- TypeScript JSX
					"typescript", -- TypeScript programming language

					-- Markup languages
					"html", -- HTML markup language
					"json", -- JSON data format
					"markdown", -- Markdown markup language
					"markdown_inline", -- Inline Markdown

					-- Git related
					"diff", -- Diff syntax
					"git_config", -- Git configuration files
					"git_rebase", -- Git rebase files
					"gitattributes", -- Git attributes files
					"gitcommit", -- Git commit messages
					"gitignore", -- Git ignore files

					-- Lua documentation
					"luadoc", -- LuaDoc documentation
					"luap", -- Lua patterns

					-- Miscellaneous
					"query", -- Query language
					"regex", -- Regular expressions
					"requirements", -- Python requirements files
					"scss", -- SCSS (Sassy CSS)
					"sql", -- SQL (Structured Query Language)
					"tmux", -- Tmux configuration
					"toml", -- TOML configuration
					"vim", -- Vim script
					"yaml", -- YAML Ain't Markup Language
					"jsdoc", -- JavaScript documentation
					"phpdoc", -- PHP documentation
				},
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			enable = false,
		},
	},

	{
		"davidmh/mdx.nvim",
		config = true,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
}

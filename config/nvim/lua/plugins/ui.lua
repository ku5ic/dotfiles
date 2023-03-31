return {
	{
		"folke/tokyonight.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			-- load the colorscheme here
			vim.cmd([[colorscheme tokyonight]])
		end,
	},


	-- bufferline
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
			{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
		},
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				always_show_bufferline = false,
				diagnostics_indicator = function(_, _, diag)
					local icons = require("config.icons").icons.diagnostics
					local ret = (diag.error and icons.Error .. diag.error .. " " or "")
					.. (diag.warning and icons.Warn .. diag.warning or "")
					return vim.trim(ret)
				end,
				offsets = {
					{
						filetype = "neo-tree",
						text = "Neo-tree",
						highlight = "Directory",
						text_align = "left",
					},
				},
			},
		},
	},

	-- statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function(plugin)
			local icons = require("config.icons").icons

			local function fg(name)
				return function()
					---@type {foreground?:number}?
					local hl = vim.api.nvim_get_hl_by_name(name, true)
					return hl and hl.foreground and { fg = string.format("#%06x", hl.foreground) }
				end
			end

			return {
				options = {
					theme = "auto",
					globalstatus = true,
					disabled_filetypes = { statusline = { "dashboard", "lazy", "alpha" } },
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = {
						{
							"diagnostics",
							symbols = {
								error = icons.diagnostics.Error,
								warn = icons.diagnostics.Warn,
								info = icons.diagnostics.Info,
								hint = icons.diagnostics.Hint,
							},
						},
						{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
						{ "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
						-- stylua: ignore
						{
							function() return require("nvim-navic").get_location() end,
							cond = function() return package.loaded["nvim-navic"] and require("nvim-navic").is_available() end,
						},
					},
					lualine_x = {
						-- stylua: ignore
						{
							function() return require("noice").api.status.command.get() end,
							cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
							color = fg("Statement")
						},
						-- stylua: ignore
						{
							function() return require("noice").api.status.mode.get() end,
							cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
							color = fg("Constant") ,
						},
						{ require("lazy.status").updates, cond = require("lazy.status").has_updates, color = fg("Special") },
						{
							"diff",
							symbols = {
								added = icons.git.added,
								modified = icons.git.modified,
								removed = icons.git.removed,
							},
						},
					},
					lualine_y = {
						{ "progress", separator = " ", padding = { left = 1, right = 0 } },
						{ "location", padding = { left = 0, right = 1 } },
					},
					lualine_z = {
						function()
							return " " .. os.date("%R")
						end,
					},
				},
				extensions = { "neo-tree" },
			}
		end,
	},
	-- maximizes and restores current window
	{
		"szw/vim-maximizer",
		keys = {
			{ "<leader>z", "<Cmd>MaximizerToggle<CR>", desc = "Toggle maximize" },
		},
	},
	{
		"goolord/alpha-nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")
            dashboard.section.header.val = {
				[[       )                                                                    ]],
				[[    ( /(             (                 (                                    ]],
				[[    )\())     (      )\   (     (      )\    (  (     (           )     (   ]],
				[[   ((_)\ (   ))\  ((((_)( )(   ))\  ((((_)(  )\))(   ))\(   (    (     ))\  ]],
				[[  __ ((_))\ /((_)  )\ _ )(()\ /((_)  )\ _ )\((_)()\ /((_)\  )\   )\  '/((_) ]],
				[[  \ \ / ((_|_))(   (_)_\(_|(_|_))    (_)_\(_)(()((_|_))((_)((_)_((_))(_))   ]],
				[[   \ V / _ \ || |   / _ \| '_/ -_)    / _ \ \ V  V / -_|_-< _ \ '  \() -_)  ]],
				[[    |_|\___/\_,_|  /_/ \_\_| \___|   /_/ \_\ \_/\_/\___/__|___/_|_|_|\___|  ]],
				[[                                                                            ]],
			}

			dashboard.section.buttons.val = {
				dashboard.button( "e", "  New file" , ":ene <BAR> startinsert <CR>"),
				dashboard.button( "q", "  Quit NVIM" , ":qa<CR>"),
			}
			local handle = io.popen('fortune')
			local fortune = handle:read("*a")
			handle:close()
			dashboard.section.footer.val = fortune
			dashboard.config.opts.noautocmd = true
			vim.cmd[[autocmd User AlphaReady echo 'ready']]
			alpha.setup(dashboard.config)
		end,
	}
}

return {
	-- auto completion
	{
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"ray-x/cmp-treesitter",
			"f3fora/cmp-spell",
		},
		config = function()
			local cmp = require("cmp")

			-- Configure nvim-cmp
			--
			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
				}),

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "copilot" },
				}),

				entry_filter = function(entry, ctx)
					local item = entry:get_completion_item()
					return item.insertTextFormat ~= 2
				end,

				formatting = {
					format = function(entry, item)
						local icons = require("config.icons").icons.kinds
						if icons[item.kind] then
							item.kind = icons[item.kind] .. item.kind
						end
						item.menu = ({
							copilot = "[Copilot]",
							path = "[Path]",
							nvim_lsp = "[LSP]",
							spell = "[Spell]",
							buffer = "[Buffer]",
						})[entry.source.name]
						return item
					end,
				},
			})
		end,
	},

	-- copilot completion
	{
		"zbirenbaum/copilot-cmp",
		config = function()
			require("copilot_cmp").setup()
		end,
	},
}

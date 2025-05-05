return {
	-- auto completion
	{
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"ray-x/cmp-treesitter",
			"L3MON4D3/LuaSnip",
			"f3fora/cmp-spell",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Helper function to check if there are words before the cursor
			local function has_words_before()
				local _, col = unpack(vim.api.nvim_win_get_cursor(0))
				if col == 0 then
					return false
				end
				return not vim.api.nvim_get_current_line():sub(col, col):match("%s")
			end

			-- Lazy load VS Code-like snippets
			require("luasnip.loaders.from_vscode").lazy_load()

			-- Define mappings for completion
			local function tab_mapping(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				elseif has_words_before() then
					cmp.complete()
				else
					fallback()
				end
			end

			local function shift_tab_mapping(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip.jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end

			-- Configure nvim-cmp
			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping(tab_mapping, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(shift_tab_mapping, { "i", "s" }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp", group_index = 1 },
					{ name = "luasnip", group_index = 1 },
					{ name = "buffer", group_index = 2 },
					{ name = "path", group_index = 2 },
					{ name = "spell", group_index = 3 },
					{ name = "copilot", group_index = 3 },
				}),
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
							luasnip = "[LuaSnip]",
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

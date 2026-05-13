return {
	{
		"saghen/blink.cmp",
		dependencies = {
			{
				"giuxtaposition/blink-cmp-copilot",
				dependencies = {
					"zbirenbaum/copilot.lua",
				},
			},
		},

		version = "1.*",
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-space: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			keymap = { preset = "enter" },
			enabled = function()
				return vim.bo.filetype ~= "copilot-chat"
			end,

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			-- (Default) Only show the documentation popup when manually triggered
			completion = {
				documentation = { auto_show = true },
				menu = {
					draw = {
						columns = {
							{ "label", "label_description", gap = 1 },
							{ "kind_icon", "kind", gap = 1 },
						},
					},
				},
			},

			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lsp", "path", "buffer", "copilot" },
				-- Drop Snippet-kind items from all providers. Standalone snippet templates
				-- (kind = Snippet) are unwanted; LSP items that merely use snippet
				-- insertTextFormat for placeholders are handled separately by snippets.expand.
				transform_items = function(_, items)
					return vim.tbl_filter(function(item)
						return item.kind ~= require("blink.cmp.types").CompletionItemKind.Snippet
					end, items)
				end,
				providers = {
					lsp = { name = "LSP" },
					path = { name = "Path" },
					buffer = { name = "Buffer" },
					copilot = {
						name = "Copilot",
						module = "blink-cmp-copilot",
						score_offset = 100,
						async = true,
					},
				},
			},
			cmdline = {
				enabled = false,
			},

			-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
			-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
			-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
			--
			-- See the fuzzy documentation for more information
			fuzzy = { implementation = "prefer_rust_with_warning" },
			-- Strip snippet placeholder syntax before expansion so LSP completions insert
			-- as plain text. Without this, blink delegates insertion entirely to expand()
			-- and a no-op expand means nothing gets inserted.
			-- snippets = {
			-- 	expand = function(snippet)
			-- 		local body = snippet
			-- 			:gsub("%${(%d+):([^}]*)}", "%2") -- ${1:placeholder} -> placeholder text
			-- 			:gsub("%${%d+}", "") -- ${1} -> nothing
			-- 			:gsub("%$%d+", "") -- $1 -> nothing
			-- 			:gsub("%$0", "") -- final cursor marker -> nothing
			-- 		vim.snippet.expand(body)
			-- 	end,
			-- },
		},
		opts_extend = { "sources.default" },
	},
}

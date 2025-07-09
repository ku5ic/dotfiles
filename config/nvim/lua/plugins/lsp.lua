return {
	{
		"mason-org/mason.nvim",
		build = ":MasonUpdate",
		dependencies = {
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			require("mason").setup({
				ui = { icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
			})

			-- LSP servers that Mason should keep present on disk
			require("mason-lspconfig").setup({
				ensure_installed = {
					"cssls",
					"emmet_ls",
					"html",
					"lua_ls",
					"phpactor",
					"solargraph",
					"ts_ls",
					"pylsp",
				},
				automatic_installation = true,
			})

			-- Stand-alone tools
			require("mason-tool-installer").setup({
				ensure_installed = {
					"cspell",
					"eslint_d",
					"js-debug-adapter",
					"php-debug-adapter",
					"prettier",
					"pylint",
					"stylelint",
					"stylua",
					"php-cs-fixer",
				},
				automatic_installation = true,
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		lazy = false, -- load at startup so first buffer gets LSP
		priority = 1000,

		config = function()
			local set_desc = require("utils").set_desc
			local icons = require("config.icons").icons.diagnostics

			-- Fancy virtual-text diagnostics
			vim.diagnostic.config({
				virtual_text = {
					prefix = function(d)
						return icons[({ "Error", "Warn", "Info", "Hint" })[d.severity]] .. " "
					end,
					spacing = 4,
					source = true,
				},
				float = { source = true },
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = icons.Error,
						[vim.diagnostic.severity.WARN] = icons.Warn,
						[vim.diagnostic.severity.INFO] = icons.Info,
						[vim.diagnostic.severity.HINT] = icons.Hint,
					},
				},
				underline = true,
				severity_sort = true,
			})

			local server_settings = {
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = {
								checkThirdParty = false,
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.stdpath("config") .. "/lua"] = true,
								},
							},
						},
					},
				},

				ts_ls = {
					filetypes = {
						"typescript",
						"typescriptreact",
						"typescript.tsx",
						"javascript",
						"javascriptreact",
						"javascript.jsx",
						"vue",
						"svelte",
						"astro",
					},
				},

				emmet_ls = { -- same idea
					filetypes = {
						"html",
						"djangohtml",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
						"svelte",
					},
				},
			}

			local capabilities = require("blink.cmp").get_lsp_capabilities()

			local servers = { "cssls", "emmet_ls", "html", "lua_ls", "phpactor", "solargraph", "ts_ls", "pylsp" }

			for _, name in ipairs(servers) do
				vim.lsp.config(
					name,
					vim.tbl_deep_extend("force", { capabilities = capabilities }, server_settings[name] or {})
				)
				vim.lsp.enable(name) -- auto-start on matching buffers
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local buf = args.buf
					local opts = { buffer = buf, silent = true, noremap = true }

					vim.keymap.set("n", "gd", vim.lsp.buf.definition, set_desc(opts, { desc = "Goto Definition" }))
					vim.keymap.set("n", "gr", vim.lsp.buf.references, set_desc(opts, { desc = "Refereces" }))
					vim.keymap.set(
						"n",
						"gI",
						vim.lsp.buf.implementation,
						set_desc(opts, { desc = "Goto Implementation" })
					)
					vim.keymap.set(
						"n",
						"gy",
						vim.lsp.buf.type_definition,
						set_desc(opts, { desc = "Goto Type Definition" })
					)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, set_desc(opts, { desc = "Goto Declaration" }))
					vim.keymap.set("n", "K", vim.lsp.buf.hover, set_desc(opts, { desc = "Hover" }))
					vim.keymap.set("n", "gk", vim.lsp.buf.signature_help, set_desc(opts, { desc = "Signature Help" }))
					vim.keymap.set(
						{ "n", "v" },
						"ca",
						vim.lsp.buf.code_action,
						set_desc(opts, { desc = "Code Action" })
					)
					vim.keymap.set({ "n", "v" }, "cc", vim.lsp.codelens.run, set_desc(opts, { desc = "Run Codelens" }))
					vim.keymap.set(
						"n",
						"gC",
						vim.lsp.codelens.refresh,
						set_desc(opts, { desc = "Referesh & Display Codelense" })
					)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, set_desc(opts, { desc = "Rename" }))
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, set_desc(opts, { desc = "Code Action" }))
					vim.keymap.set(
						"n",
						"<leader>wa",
						vim.lsp.buf.add_workspace_folder,
						set_desc(opts, { desc = "Add WS Folder" })
					)
					vim.keymap.set(
						"n",
						"<leader>wr",
						vim.lsp.buf.remove_workspace_folder,
						set_desc(opts, { desc = "Remove WS Folder" })
					)
					vim.keymap.set("n", "<leader>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, set_desc(opts, { desc = "List WS Folders" }))
				end,
			})
		end,
	},
}

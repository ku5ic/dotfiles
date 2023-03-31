return {
	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"jayp0521/mason-null-ls.nvim",
			"jose-elias-alvarez/null-ls.nvim",
		},
		config = function()
			-- enable mason
			require("mason").setup()

			require("mason-lspconfig").setup({
				-- list of servers for mason to install
				ensure_installed = {
					"tsserver",
					"html",
					"cssls",
					-- "lua_ls",
					"emmet_ls",
					"solargraph",
					"phpactor",
				},
				-- auto-install configured servers (with lspconfig)
				automatic_installation = true, -- not the same as ensure_installed
			})

			require("mason-null-ls").setup({
				-- list of formatters & linters for mason to install
				ensure_installed = {
					"prettier", -- ts/js formatter
					"stylua", -- lua formatter
					"eslint_d", -- ts/js linter
					"rubocop",
					"phpcbf",
					"phpcs",
				},
				-- auto-install configured formatters & linters (with null-ls)
				automatic_installation = true,
			})
		end,
	},

	{
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			-- import null-ls plugin safely
			local setup, null_ls = pcall(require, "null-ls")
			if not setup then
				return
			end

			-- for conciseness
			local formatting = null_ls.builtins.formatting -- to setup formatters
			local diagnostics = null_ls.builtins.diagnostics -- to setup diagnostics
			local code_actions = null_ls.builtins.code_actions -- to setup code_actions
			local completion = null_ls.builtins.completion -- to setup completion

			-- configure null_ls
			null_ls.setup({
				-- setup formatters & linters
				sources = {
					--  to disable file types use
					--  "formatting.prettier.with({disabled_filetypes: {}})" (see null-ls docs)

					-- formatting
					formatting.prettier, -- js/ts formatter
					formatting.stylua, -- lua formatter
					formatting.rubocop, -- ruby formatter
					formatting.phpcbf, -- php formatter

					-- diagnostics
					diagnostics.eslint_d.with({
						diagnostics_format = "[eslint] #{m}\n(#{c})",
					}), -- js/ts linter
					diagnostics.rubocop, -- ruby linter
					diagnostics.phpcs, -- php linter

					-- completion
					completion.spell, -- spell checker

					-- code actions
					code_actions.gitsigns, -- code actions for gitsigns
					require("typescript.extensions.null-ls.code-actions") -- code actions for typescript
				},
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"onsails/lspkind.nvim",
			"jose-elias-alvarez/typescript.nvim"
		},
		event = "InsertEnter",
		config = function()
			local lspconfig = require("lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local keymap = vim.keymap -- for conciseness
			local set_desc = require("utils").set_desc

			-- nvim-cmp supports additional completion capabilities
			-- local capabilities = vim.lsp.protocol.make_client_capabilities()
			-- capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
			local capabilities = require('cmp_nvim_lsp').default_capabilities()

			-- Change diagnostic symbols in the sign column (gutter)
			local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
			end

			local opts = { noremap = true, silent = true }

			-- Customizing how diagnostics are displayed
			vim.diagnostic.config({
				-- virtual_text = {
				-- 	source = --- "always", -- Or "if_many"
				-- 	prefix = "●", -- Could be '■', '▎', 'x'
				-- },
				virtual_text = false,
				float = {
					source = "always", -- Or "if_many"
				},
				table = {
					source = "always", -- Or "if_many"
				},
				signs = true,
				severity_sort = true,
			})

			keymap.set("n", "<leader>e", vim.diagnostic.open_float, set_desc(opts, { desc = "Show Line Diagnostics" }))
			keymap.set("n", "[d", vim.diagnostic.goto_prev, set_desc(opts, { desc = "Go to Previous Diagnostic" }))
			keymap.set("n", "]d", vim.diagnostic.goto_next, set_desc(opts, { desc = "Go to Next Diagnostic" }))
			keymap.set("n", "<leader>q", vim.diagnostic.setloclist, set_desc(opts, { desc = "Set Location List" }))

			local on_attach = function(client, bufnr)
				-- Mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local bufopts = { noremap = true, silent = true, buffer = bufnr }
				keymap.set("n", "gD", vim.lsp.buf.declaration, set_desc(bufopts, { desc = "Go to Declaration" }))
				keymap.set("n", "gd", vim.lsp.buf.definition, set_desc(bufopts, { desc = "Go to Definition" }))
				keymap.set("n", "K", vim.lsp.buf.hover, set_desc(bufopts, { desc = "Show Hover" }))
				keymap.set("n", "gi", vim.lsp.buf.implementation, set_desc(bufopts, { desc = "Go to Implementation" }))
				keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, set_desc(bufopts, { desc = "Show Signature Help" }))
				keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, set_desc(bufopts, { desc = "Add Workspace Folder" }))
				keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, set_desc(bufopts, { desc = "Remove Workspace Folder" }))
				keymap.set("n", "<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, set_desc(bufopts, { desc = "List Workspace Folders" }))
				keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, set_desc(bufopts, { desc = "Go to Type Definition" }))
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, set_desc(bufopts, { desc = "Rename" }))
				keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, set_desc(bufopts, { desc = "Code Action" }))
				keymap.set("n", "gr", vim.lsp.buf.references, set_desc(bufopts, { desc = "Go to References" }))
				keymap.set("n", "<leader>f", function()
					vim.lsp.buf.format({ async = true })
					end, set_desc(bufopts, { desc = "Format Document" }))

				if client.name == "tsserver" then
					keymap.set("n", "<leader>co", "<cmd>TypescriptOrganizeImports<CR>", set_desc(bufopts, { desc = "Organize Imports" }))
					keymap.set("n", "<leader>cR", "<cmd>TypescriptRenameFile<CR>", set_desc(bufopts, { desc = "Rename File" }))
				end
			end

			-- configure html server
			lspconfig["html"].setup({
				on_attach = on_attach,
				capabilities = capabilities,
			})

			-- configure typescript server with plugin
			require("typescript").setup({
				disable_commands = false, -- prevent the plugin from creating Vim commands
				debug = false, -- enable debug logging for commands
				go_to_source_definition = {
					fallback = true, -- fall back to standard LSP definition on failure
				},
				server = { -- pass options to lspconfig's setup method
					on_attach = on_attach,
					capabilities = capabilities,
					filetypes = { "typescript", "typescriptreact", "typescript.tsx", "javascriptreact", "javascript" },
					diagnostics = {
						format = function(diagnostic)
							return string.format("[tsserver] %s", diagnostic.message)
						end,
					},
					settings = {
						completions = {
							completeFunctionCalls = true,
						},
					},
				},
			})
			-- lspconfig["tsserver"].setup({
			-- 	on_attach = on_attach,
			-- 	capabilities = capabilities,
			-- 	filetypes = { "typescript", "typescriptreact", "typescript.tsx", "javascriptreact", "javascript" },
			-- 	diagnostics = {
			-- 		format = function(diagnostic)
			-- 			return string.format("[tsserver] %s", diagnostic.message)
			-- 		end,
			-- 	},
			-- 	settings = {
			-- 		completions = {
			-- 			completeFunctionCalls = true,
			-- 		},
			-- 	},
			-- })

			-- configure ruby server plugin
			lspconfig["solargraph"].setup({
				on_attach = on_attach,
				capabilities = capabilities,
			})

			-- configure php server plugin
			lspconfig["phpactor"].setup({
				on_attach = on_attach,
				capabilities = capabilities,
			})

			-- configure css server
			lspconfig["cssls"].setup({
				on_attach = on_attach,
				capabilities = capabilities,
			})

			-- configure emmet language server
			lspconfig["emmet_ls"].setup({
				on_attach = on_attach,
				capabilities = capabilities,
				filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
			})

			-- configure lua server (with special settings)
			--		lspconfig["lua_ls"].setup({
			--			on_attach = on_attach,
			--			capabilities = capabilities,
			--			settings = { -- custom settings for lua
			--				Lua = {
			--					-- make the language server recognize "vim" global
			--					diagnostics = {
			--						globals = { "vim" },
			--					},
			--					workspace = {
			--						-- make language server aware of runtime files
			--						library = {
			--							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
			--							[vim.fn.stdpath("config") .. "/lua"] = true,
			--						},
			--					},
			--				},
			--			},
			--		})
		end,
	},
}

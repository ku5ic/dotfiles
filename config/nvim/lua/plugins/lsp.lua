local keymap = vim.keymap -- for conciseness
local set_desc = require("utils").set_desc

-- Function to set up diagnostic symbols
local function setup_diagnostic_symbols()
	for name, icon in pairs(require("config.icons").icons.diagnostics) do
		name = "DiagnosticSign" .. name
		vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
	end
end

-- Function to configure diagnostics display
local function configure_diagnostics()
	vim.diagnostic.config({
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
end

-- Function to set up diagnostic key mappings
local function setup_diagnostic_keymaps(opts)
	keymap.set("n", "<leader>e", vim.diagnostic.open_float, set_desc(opts, { desc = "Show Line Diagnostics" }))
	keymap.set("n", "[d", vim.diagnostic.goto_prev, set_desc(opts, { desc = "Go to Previous Diagnostic" }))
	keymap.set("n", "]d", vim.diagnostic.goto_next, set_desc(opts, { desc = "Go to Next Diagnostic" }))
	keymap.set("n", "<leader>q", vim.diagnostic.setloclist, set_desc(opts, { desc = "Set Location List" }))
end

-- Function to set up LSP key mappings
local function setup_lsp_keymaps(client, bufnr)
	local bufopts = { noremap = true, silent = true, buffer = bufnr }
	keymap.set("n", "gD", vim.lsp.buf.declaration, set_desc(bufopts, { desc = "Go to Declaration" }))
	keymap.set("n", "gd", vim.lsp.buf.definition, set_desc(bufopts, { desc = "Go to Definition" }))
	keymap.set("n", "K", vim.lsp.buf.hover, set_desc(bufopts, { desc = "Show Hover" }))
	keymap.set("n", "gi", vim.lsp.buf.implementation, set_desc(bufopts, { desc = "Go to Implementation" }))
	keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, set_desc(bufopts, { desc = "Show Signature Help" }))
	keymap.set(
		"n",
		"<leader>wa",
		vim.lsp.buf.add_workspace_folder,
		set_desc(bufopts, { desc = "Add Workspace Folder" })
	)
	keymap.set(
		"n",
		"<leader>wr",
		vim.lsp.buf.remove_workspace_folder,
		set_desc(bufopts, { desc = "Remove Workspace Folder" })
	)
	keymap.set("n", "<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, set_desc(bufopts, { desc = "List Workspace Folders" }))
	keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, set_desc(bufopts, { desc = "Go to Type Definition" }))
	keymap.set("n", "<leader>rn", vim.lsp.buf.rename, set_desc(bufopts, { desc = "Rename" }))
	keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, set_desc(bufopts, { desc = "Code Action" }))
	keymap.set("n", "gr", vim.lsp.buf.references, set_desc(bufopts, { desc = "Go to References" }))

	if client.name == "ts_ls" then
		keymap.set(
			"n",
			"<leader>co",
			"<cmd>TypescriptOrganizeImports<CR>",
			set_desc(bufopts, { desc = "Organize Imports" })
		)
		keymap.set("n", "<leader>cR", "<cmd>TypescriptRenameFile<CR>", set_desc(bufopts, { desc = "Rename File" }))
	end
end

-- Function to configure LSP servers
local function configure_servers(servers, capabilities, lspconfig)
	for key, value in pairs(servers) do
		lspconfig[key].setup(vim.tbl_deep_extend("force", {
			on_attach = function(client, bufnr)
				setup_lsp_keymaps(client, bufnr)
			end,
			capabilities = capabilities,
		}, value))
	end
end

return {
	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			-- enable mason
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})

			require("mason-lspconfig").setup({
				-- list of servers for mason to install
				ensure_installed = {
					"cssls", -- css language server
					"emmet_ls", -- emmet language server
					"html", -- html language server
					"lua_ls", -- lua language server
					"phpactor", -- php language server
					"solargraph", -- ruby language server
					"ts_ls", -- typescript language server
				},
				-- auto-install configured servers (with lspconfig)
				automatic_installation = true, -- not the same as ensure_installed
			})

			require("mason-tool-installer").setup({
				ensure_installed = {
					"cspell", -- spell checker
					"eslint_d", -- js linter
					"js-debug-adapter", -- js debugger
					"php-debug-adapter", -- php debugger
					"prettier", -- prettier formatter
					"pylint", -- python linter
					"stylelint", -- css linter
					"stylua", -- lua formatter
					"php-cs-fixer", -- php formatter
				},
				-- auto-install configured servers (with lspconfig)
				automatic_installation = true, -- not the same as ensure_installed
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			-- "jose-elias-alvarez/typescript.nvim",
		},
		event = "InsertEnter",
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local servers = {
				html = {},
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
				solargraph = {},
				phpactor = {},
				cssls = {},
				emmet_ls = {
					filetypes = {
						"html",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
						"svelte",
					},
				},
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = {
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.stdpath("config") .. "/lua"] = true,
								},
							},
						},
					},
				},
			}

			setup_diagnostic_symbols()
			configure_diagnostics()
			setup_diagnostic_keymaps({ noremap = true, silent = true })
			configure_servers(servers, capabilities, lspconfig)
		end,
	},
}

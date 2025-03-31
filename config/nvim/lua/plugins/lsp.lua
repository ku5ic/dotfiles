local keymap = vim.keymap -- for conciseness
local set_desc = require("utils").set_desc

-- Function to configure diagnostics display
local function configure_diagnostics()
	local icons = require("config.icons").icons.diagnostics
	vim.diagnostic.config({
		virtual_text = {
			prefix = "●", -- Could be '●', '▎', 'x'
			spacing = 4,
			source = true, -- Or "if_many"
		},
		float = {
			source = true, -- Or "if_many"
		},
		table = {
			source = "always", -- Or "if_many"
		},
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
end

-- Function to set up diagnostic key mappings
local function setup_diagnostic_keymaps(opts)
	keymap.set("n", "<leader>e", vim.diagnostic.open_float, set_desc(opts, { desc = "Show Line Diagnostics" }))
	keymap.set("n", "[d", function()
		vim.diagnostic.jump({ count = 1, float = true })
	end, set_desc(opts, { desc = "Go to Previous Diagnostic" }))
	keymap.set("n", "]d", function()
		vim.diagnostic.jump({ count = -1, float = true })
	end, set_desc(opts, { desc = "Go to Next Diagnostic" }))
	keymap.set("n", "<leader>q", vim.diagnostic.setloclist, set_desc(opts, { desc = "Set Location List" }))
end

local function organize_imports(bufnr)
	-- Get the current buffer number if none is provided
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	-- Parameters for the request
	local params = {
		command = "_typescript.organizeImports",
		arguments = { vim.api.nvim_buf_get_name(bufnr) },
		title = "",
	}

	-- Perform a synchronous request with a 500ms timeout
	-- Depending on the size of the file, a larger timeout may be needed
	vim.lsp.buf_request(bufnr, "workspace/executeCommand", params, function(err, result, ctx)
		if err then
			vim.notify("Error organizing imports: " .. err.message, vim.log.levels.ERROR)
		elseif result then
			vim.notify("Imports organized successfully", vim.log.levels.INFO)
		end
	end)
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
		keymap.set("n", "<leader>co", function()
			organize_imports(bufnr)
		end, set_desc(bufopts, { desc = "Organize Imports" }))
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
								checkThirdParty = false,
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.stdpath("config") .. "/lua"] = true,
								},
							},
						},
					},
				},
			}

			configure_diagnostics()
			setup_diagnostic_keymaps({ noremap = true, silent = true })
			configure_servers(servers, capabilities, lspconfig)
		end,
	},
}

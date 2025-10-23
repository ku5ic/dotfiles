-- Toggle between TypeScript LSP servers: "ts_ls" or "vtsls"
local typescript_lsp = "vtsls" -- Change this to "ts_ls" to switch

-- Extract server configurations into a separate module-level function
local function get_server_settings()
	return {
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

		vtsls = {
			settings = {
				vtsls = {
					autoUseWorkspaceTsdk = true,
					experimental = {
						maxInlayHintLength = 30,
						completion = {
							enableServerSideFuzzyMatch = true,
						},
					},
				},
				typescript = {
					updateImportsOnFileMove = { enabled = "always" },
					suggest = { completeFunctionCalls = true },
					inlayHints = {
						enumMemberValues = { enabled = true },
						functionLikeReturnTypes = { enabled = true },
						parameterNames = { enabled = "literals" },
						parameterTypes = { enabled = true },
						propertyDeclarationTypes = { enabled = true },
						variableTypes = { enabled = false },
					},
				},
				javascript = {
					updateImportsOnFileMove = { enabled = "always" },
					inlayHints = {
						enumMemberValues = { enabled = true },
						functionLikeReturnTypes = { enabled = true },
						parameterNames = { enabled = "literals" },
						parameterTypes = { enabled = true },
						propertyDeclarationTypes = { enabled = true },
						variableTypes = { enabled = false },
					},
				},
			},
		},

		ts_ls = {
			init_options = {
				maxTsServerMemory = 8192,
				tsserver = { logVerbosity = "off" },
			},
			settings = {
				typescript = { inlayHints = { enabled = false } },
				javascript = { inlayHints = { enabled = false } },
			},
			filetypes = {
				"astro",
				"javascript",
				"javascript.jsx",
				"javascriptreact",
				"svelte",
				"typescript",
				"typescript.tsx",
				"typescriptreact",
				"vue",
			},
		},

		tailwindcss = {
			settings = {
				tailwindCSS = {
					experimental = {
						classRegex = {
							{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
							{ "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
							{ "cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
						},
					},
				},
			},
		},

		emmet_ls = {
			filetypes = {
				"css",
				"djangohtml",
				"html",
				"javascriptreact",
				"less",
				"sass",
				"scss",
				"svelte",
				"typescriptreact",
			},
		},
	}
end

-- Extract Mason setup into a separate function
local function setup_mason()
	require("mason").setup({
		ui = {
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
	})

	-- LSP servers list
	local lsp_servers = {
		"cssls",
		"emmet_ls",
		"html",
		"lua_ls",
		"phpactor",
		"pylsp",
		"solargraph",
		"tailwindcss",
		typescript_lsp,
	}

	require("mason-lspconfig").setup({
		ensure_installed = lsp_servers,
		automatic_installation = true,
	})

	-- Stand-alone tools
	require("mason-tool-installer").setup({
		ensure_installed = {
			"cspell",
			"eslint_d",
			"js-debug-adapter",
			"php-cs-fixer",
			"php-debug-adapter",
			"prettier",
			"prettierd",
			"pylint",
			"stylelint",
			"stylua",
		},
		automatic_installation = true,
	})
end

-- Extract diagnostic configuration
local function configure_diagnostics()
	local icons = require("config.icons").icons.diagnostics

	vim.diagnostic.config({
		virtual_text = {
			prefix = function(d)
				local severity_names = { "Error", "Warn", "Info", "Hint" }
				return icons[severity_names[d.severity]] .. " "
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
end

-- Extract LSP server setup
local function setup_lsp_servers()
	local capabilities = require("blink.cmp").get_lsp_capabilities()
	local server_settings = get_server_settings()

	local servers = {
		"cssls",
		"emmet_ls",
		"html",
		"lua_ls",
		"phpactor",
		"pylsp",
		"solargraph",
		"tailwindcss",
		typescript_lsp,
	}

	-- Disable the non-selected TypeScript LSP
	local disabled_ts_lsp = typescript_lsp == "vtsls" and "ts_ls" or "vtsls"
	vim.lsp.config(disabled_ts_lsp, { enabled = false })

	-- Configure and enable each server
	for _, name in ipairs(servers) do
		local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, server_settings[name] or {})
		vim.lsp.config(name, config)
		vim.lsp.enable(name)
	end
end

-- Extract LSP keymaps setup
local function setup_lsp_keymaps(buf, client)
	local set_desc = require("utils").set_desc
	local opts = { buffer = buf, silent = true, noremap = true }

	-- Navigation keymaps
	local keymaps = {
		{ "n", "gd", vim.lsp.buf.definition, "Goto Definition" },
		{ "n", "gr", vim.lsp.buf.references, "Goto References" },
		{ "n", "gI", vim.lsp.buf.implementation, "Goto Implementation" },
		{ "n", "gy", vim.lsp.buf.type_definition, "Goto Type Definition" },
		{ "n", "K", vim.lsp.buf.hover, "Hover Documentation" },
		{ "n", "gk", vim.lsp.buf.signature_help, "Signature Help" },
		{ { "n", "v" }, "cc", vim.lsp.codelens.run, "Run Codelens" },
		{ "n", "gC", vim.lsp.codelens.refresh, "Refresh Codelens" },
	}

	for _, map in ipairs(keymaps) do
		local modes, key, action, desc = map[1], map[2], map[3], map[4]
		vim.keymap.set(modes, key, action, set_desc(opts, { desc = desc }))
	end

	-- Conditional declaration keymap
	if client and client.server_capabilities.declarationProvider then
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, set_desc(opts, { desc = "Goto Declaration" }))
	end
end

return {
	{
		"mason-org/mason.nvim",
		build = ":MasonUpdate",
		dependencies = {
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = setup_mason,
	},

	{
		"neovim/nvim-lspconfig",
		lazy = false,
		priority = 1000,
		config = function()
			configure_diagnostics()
			setup_lsp_servers()

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					setup_lsp_keymaps(args.buf, client)
				end,
			})
		end,
	},

	{
		"folke/trouble.nvim",
		opts = {},
		cmd = "Trouble",
	},
}

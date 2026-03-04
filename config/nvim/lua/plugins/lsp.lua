-- Toggle between TypeScript LSP servers: "ts_ls" or "vtsls"
local typescript_lsp = "ts_ls" -- Change this to "vtsls" to switch

-- Single source of truth for all managed LSP servers.
-- Both Mason and the LSP setup derive from this list.
local LSP_SERVERS = {
	"basedpyright",
	"cssls",
	"emmet_ls",
	"html",
	"lua_ls",
	"phpactor",
	"ruff",
	"solargraph",
	"tailwindcss",
	typescript_lsp,
}

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

		cssls = {
			settings = {
				css = {
					lint = {
						unknownAtRules = "ignore",
					},
				},
				scss = {
					lint = {
						unknownAtRules = "ignore",
					},
				},
				less = {
					lint = {
						unknownAtRules = "ignore",
					},
				},
			},
		},

		basedpyright = {
			settings = {
				basedpyright = {
					analysis = {
						typeCheckingMode = "standard",
						autoImportCompletions = true,
						diagnosticMode = "openFilesOnly",
					},
					reportIncompatibleVariableOverride = "none",
					reportIncompatibleMethodOverride = "none",
				},
			},
		},

		ruff = {
			on_attach = function(client)
				client.server_capabilities.hoverProvider = false
			end,
		},
	}
end

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

	require("mason-lspconfig").setup({
		ensure_installed = LSP_SERVERS,
		automatic_installation = true,
	})

	-- Stand-alone tools (formatters, linters, debuggers)
	require("mason-tool-installer").setup({
		ensure_installed = {
			"cspell",
			"eslint",
			"js-debug-adapter",
			"php-cs-fixer",
			"php-debug-adapter",
			"prettier",
			"prettierd",
			"black",
			"ruff",
			"stylelint",
			"stylua",
			"djlint",
		},
		automatic_installation = true,
	})
end

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

local function setup_lsp_servers()
	local capabilities = require("blink.cmp").get_lsp_capabilities()
	local server_settings = get_server_settings()

	-- Disable whichever TypeScript LSP is not selected
	local disabled_ts_lsp = typescript_lsp == "vtsls" and "ts_ls" or "vtsls"
	vim.lsp.config(disabled_ts_lsp, { enabled = false })

	for _, name in ipairs(LSP_SERVERS) do
		local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, server_settings[name] or {})
		vim.lsp.config(name, config)
		vim.lsp.enable(name)
	end
end

local function setup_lsp_keymaps(bufnr, client)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
	vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "References" })
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to implementation" })
	vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Go to type definition" })
	vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover documentation" })
	vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })

	if client and client.server_capabilities.codeLensProvider then
		vim.lsp.codelens.refresh()
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			buffer = bufnr,
			callback = function()
				vim.lsp.codelens.refresh()
			end,
		})
		vim.keymap.set({ "n", "v" }, "<leader>lc", vim.lsp.codelens.run, { buffer = bufnr, desc = "Run Codelens" })
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

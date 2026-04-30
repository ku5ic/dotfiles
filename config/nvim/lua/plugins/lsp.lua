-- Toggle between TypeScript LSP servers: "ts_ls" or "vtsls"
local typescript_lsp = "ts_ls" -- Change this to "vtsls" to switch

-- Discovery: each file under lua/lsp/servers/ is one LSP server.
-- Adding a server is dropping a file there; nothing else to edit.
local function discover_server_names()
	local dir = vim.fn.stdpath("config") .. "/lua/lsp/servers"
	local files = vim.fn.readdir(dir)
	local names = {}
	for _, file in ipairs(files) do
		if file:match("%.lua$") then
			local name = file:gsub("%.lua$", "")
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

-- Filter out the inactive ts_ls/vtsls (the toggle keeps both files on disk).
local function active_server_names()
	local skip = typescript_lsp == "vtsls" and "ts_ls" or "vtsls"
	local result = {}
	for _, name in ipairs(discover_server_names()) do
		if name ~= skip then
			table.insert(result, name)
		end
	end
	return result
end

local LSP_SERVERS = active_server_names()

local function get_server_settings(name)
	local ok, settings = pcall(require, "lsp.servers." .. name)
	return ok and settings or {}
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

	-- Defensive: explicitly disable the inactive TS server.
	local disabled_ts_lsp = typescript_lsp == "vtsls" and "ts_ls" or "vtsls"
	vim.lsp.config(disabled_ts_lsp, { enabled = false })

	for _, name in ipairs(LSP_SERVERS) do
		local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, get_server_settings(name))
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
		vim.lsp.codelens.enable(true, { buffer = bufnr })
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			group = "dotfiles_lsp_codelens",
			buffer = bufnr,
			callback = function()
				vim.lsp.codelens.enable(true, { buffer = bufnr })
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
		dependencies = {
			"saghen/blink.cmp",
		},
		config = function()
			configure_diagnostics()
			setup_lsp_servers()

			vim.api.nvim_create_augroup("dotfiles_lsp_codelens", { clear = true })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("dotfiles_lsp_attach", { clear = true }),
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

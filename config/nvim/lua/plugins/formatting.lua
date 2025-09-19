return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	-- Keymaps moved to main keymaps.lua for consistency
	-- Everything in opts will be passed to setup()
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			svelte = { "prettier" },
			css = { "prettier" },
			html = { "prettier" },
			htmldjango = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			lua = { "stylua" },
			python = { "autopep8", "isort" },
			php = { "php_cs_fixer" },
		},
		-- Set up format-on-save
		format_on_save = {
			lsp_fallback = true,
			async = false,
			timeout_ms = 500,
		},
	},
}

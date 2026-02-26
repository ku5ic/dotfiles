return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			javascript = { "prettier", stop_after_first = true },
			typescript = { "prettier", stop_after_first = true },
			javascriptreact = { "prettier", stop_after_first = true },
			typescriptreact = { "prettier", stop_after_first = true },
			css = { "prettier", stop_after_first = true },
			html = { "prettier", stop_after_first = true },
			htmldjango = { "djlint", stop_after_first = true },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			lua = { "stylua" },
			python = { "ruff_fix", "black" },
			php = { "php_cs_fixer" },
		},
		-- Set up format-on-save
		format_on_save = {
			lsp_fallback = true,
			async = false,
			timeout_ms = 2000,
		},
	},
}

local filetypes = require("config.filetypes")
local prettier_first = { "prettier", stop_after_first = true }

local formatters_by_ft = {
	css = prettier_first,
	html = prettier_first,
	htmldjango = { "djlint", stop_after_first = true },
	json = { "prettier" },
	yaml = { "prettier" },
	markdown = { "prettier" },
	lua = { "stylua" },
	python = { "ruff_format", "ruff" },
	php = { "php_cs_fixer" },
}

for _, ft in ipairs(filetypes.JS_TS) do
	formatters_by_ft[ft] = prettier_first
end

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
		formatters_by_ft = formatters_by_ft,
		format_on_save = {
			lsp_fallback = true,
			async = false,
			timeout_ms = 2000,
		},
	},
}

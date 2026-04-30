return {
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
}

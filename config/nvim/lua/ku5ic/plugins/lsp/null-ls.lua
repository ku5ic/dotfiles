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
		formatting.rubocop,

		-- diagnostics
		diagnostics.eslint_d,
		diagnostics.rubocop,

		-- completion
		completion.spell,
		completion.tsserver,

		-- code actions
		code_actions.gitsigns,
	},
})

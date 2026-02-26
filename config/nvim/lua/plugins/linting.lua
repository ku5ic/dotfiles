return {
	"mfussenegger/nvim-lint",
	event = {
		"BufReadPre",
		"BufNewFile",
	},
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint" },
			typescript = { "eslint" },
			javascriptreact = { "eslint" },
			typescriptreact = { "eslint" },
			svelte = { "eslint" },
			css = { "stylelint" },
			scss = { "stylelint" },
			sass = { "stylelint" },
		}

		lint.linters.stylelint = require("lint.util").wrap(lint.linters.stylelint, function(diagnostic)
			if diagnostic.message:find("Stylelint error, run `stylelint") then
				return nil
			end
			return diagnostic
		end)

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				local bufdir = vim.fn.expand("%:p:h")
				local local_eslint = vim.fn.findfile("node_modules/.bin/eslint", bufdir .. ";")
				lint.linters.eslint.cmd = local_eslint ~= "" and vim.fn.fnamemodify(local_eslint, ":p") or "eslint"
				lint.try_lint()
			end,
		})
	end,
}

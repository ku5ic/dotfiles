return {
	"mfussenegger/nvim-lint",
	event = {
		"BufReadPre",
		"BufNewFile",
	},
	keys = {
		{
			"<leader>ll",
			function()
				require("lint").try_lint()
			end,
			desc = "Lint current file",
		},
	},
	config = function()
		local lint = require("lint")
		local filetypes = require("config.filetypes")

		local linters_by_ft = {
			svelte = { "eslint" },
			css = { "stylelint" },
			scss = { "stylelint" },
			sass = { "stylelint" },
		}

		for _, ft in ipairs(filetypes.JS_TS) do
			linters_by_ft[ft] = { "eslint" }
		end

		lint.linters_by_ft = linters_by_ft

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

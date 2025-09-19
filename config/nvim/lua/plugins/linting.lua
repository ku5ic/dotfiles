return {
	"mfussenegger/nvim-lint",
	event = {
		"BufReadPre",
		"BufNewFile",
	},
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			svelte = { "eslint_d" },
			python = { "pylint" },
			css = { "stylelint" },
			scss = { "stylelint" },
			sass = { "stylelint" },
		}

		--- Returns the path to the appropriate `pylint` executable.
		--
		-- The function checks for `pylint` in the following order:
		-- 1. The current Python virtual environment's `bin` directory (if `VIRTUAL_ENV` is set).
		-- 2. The Mason-managed `pylint` binary (installed via Mason.nvim).
		-- 3. The system-wide `pylint` available in the user's PATH.
		--
		-- @return string Path to the `pylint` executable.
		--
		-- @usage
		--   local pylint_cmd = get_pylint_cmd()
		local function get_pylint_cmd()
			local venv = os.getenv("VIRTUAL_ENV")
			local uv = vim.loop

			if venv then
				local venv_pylint = venv .. "/bin/pylint"
				if uv.fs_stat(venv_pylint) then
					return venv_pylint
				end
			end

			-- Fallback to Mason-installed pylint
			local mason_pylint = vim.fn.stdpath("data") .. "/mason/bin/pylint"
			if uv.fs_stat(mason_pylint) then
				return mason_pylint
			end

			-- Fallback to system pylint
			return "pylint"
		end

		-- Set the command for the pylint linter to the resolved path.
		-- This ensures that the linter uses the most appropriate pylint executable.
		lint.linters.pylint.cmd = get_pylint_cmd()

		-- ignore "No configuration found" error for eslint_d and stylelint
		lint.linters.eslint_d = require("lint.util").wrap(lint.linters.eslint_d, function(diagnostic)
			if diagnostic.message:find("Error: Could not find config file") then
				return nil
			end
			return diagnostic
		end)

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
				lint.try_lint()
			end,
		})

		-- Keymap moved to main keymaps.lua for consistency
	end,
}

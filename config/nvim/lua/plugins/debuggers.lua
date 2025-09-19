return {
	{
		"mfussenegger/nvim-dap",
		-- Keymaps moved to main keymaps.lua for consistency
		config = function()
			local dap = require("dap")

			dap.adapters.php = {
				type = "executable",
				command = os.getenv("HOME") .. "/.local/share/nvim/mason/bin/php-debug-adapter",
			}

			dap.configurations.php = {
				{
					type = "php",
					request = "launch",
					name = "Listen for xdebug",
					port = "9003",
					log = true,
				},
			}

			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" }
			)
		end,
	},

	-- mason.nvim integration
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = "mason.nvim",
		cmd = { "DapInstall", "DapUninstall" },
		opts = {
			-- You'll need to check that you have the required things installed
			-- online, please don't ask me how to install them :)
			ensure_installed = {
				-- Update this to ensure that you have the debuggers for the langs you want
				"php",
				"js",
			},
		},
	},
}

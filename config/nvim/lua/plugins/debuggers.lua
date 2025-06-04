return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			-- DAP
			{ "<F5>", "<cmd>lua require'dap'.continue()<cr>", desc = "Debugger Continue" },
			{ "<F10>", "<cmd>lua require'dap'.step_over()<cr>", desc = "Debugger Step Over" },
			{ "<F11>", "<cmd>lua require'dap'.step_into()<cr>", desc = "Debugger Step Into" },
			{ "<F12>", "<cmd>lua require'dap'.step_out()<cr>", desc = "Debugger Step Out" },
			{ "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Debugger Toggle Breakpoint" },
			{ "<leader>dr", "<cmd>lua require'dap'.repl.open()<cr>", desc = "Debugger Open Repl" },
			{ "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>", desc = "Debugger Run Last" },
			{ "<leader>dt", "<cmd>lua require'dap'.terminate()<cr>", desc = "Debugger Terminate" },
			{ "<leader>dh", "<cmd>lua require'dap.ui.widgets'.hover()<cr>", desc = "Debugger Hover" },
			{ "<leader>dp", "<cmd>lua require'dap.ui.widgets'.preview()<cr>", desc = "Debugger Preview" },
			{
				"<leader>df",
				"<cmd>lua require'dap.ui.widgets'.centered_float(require'dap.ui.widgets'.frames)<cr>",
				desc = "Debugger Frames",
			},
			{
				"<leader>ds",
				"<cmd>lua require'dap.ui.widgets'.centered_float(require'dap.ui.widgets'.scopes)<cr>",
				desc = "Debugger Scopes",
			},
		},
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

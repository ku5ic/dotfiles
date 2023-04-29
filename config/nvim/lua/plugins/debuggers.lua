return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"ravenxrz/DAPInstall.nvim",
		},
		keys = {
			-- DAP
			{ "<F5>",       "<cmd>lua require'dap'.continue()<cr>",           desc = "Debugger Continue" },
			{ "<F10>",      "<cmd>lua require'dap'.step_over()<cr>",          desc = "Debugger Step Over" },
			{ "<F11>",      "<cmd>lua require'dap'.step_into()<cr>",          desc = "Debugger Step Into" },
			{ "<F12>",      "<cmd>lua require'dap'.step_out()<cr>",           desc = "Debugger Step Into" },
			{ "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>",  desc = "Debugger Toggle Breakpoint" },
			{ "<leader>dr", "<cmd>lua require'dap'.repl.open()<cr>",          desc = "Debugger Open Repl" },
			{ "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>",           desc = "Debugger Run Last" },
			{ "<leader>dt", "<cmd>lua require'dap'.terminate()<cr>",          desc = "Debugger Terminate" },
			{ "<leader>dh", "<cmd>lua require'dap.ui.widgets'.hover()<cr>",   desc = "Debugger Hover" },
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
			local dap_install = require("dap-install")

			dap_install.setup({
				installation_path = vim.fn.stdpath("data") .. "/dapinstall/",
			})

			dap.adapters.php = {
				type = "executable",
				command = "node",
				args = { os.getenv("HOME") .. "/.local/share/nvim/dapinstall/php/vscode-php-debug/out/phpDebug.js" },
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
}

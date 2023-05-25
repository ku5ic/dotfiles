return {
	{
		"mfussenegger/nvim-dap",
		dependencies = "jay-babu/mason-nvim-dap.nvim",
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
			},
			-- Makes a best effort to setup the various debuggers with
			-- reasonable debug configurations
			automatic_installation = true,
			-- You can provide additional configuration to the handlers,
			-- see mason-nvim-dap README for more information
			handlers = {
				function(config)
					-- all sources with no handler get passed here

					-- Keep original functionality
					require("mason-nvim-dap").default_setup(config)
				end,
				php = function(config)
					config.adapters = {
						type = "executable",
						command = os.getenv("HOME") .. "/.local/share/nvim/mason/bin/php-debug-adapter",
					}
					require("mason-nvim-dap").default_setup(config) -- don't forget this!
				end,
			},
		},
	},
}

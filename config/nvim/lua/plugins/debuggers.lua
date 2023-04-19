return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"ravenxrz/DAPInstall.nvim",
		},
		keys = {
			-- DAP
			{"<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Debugger Toggle Breakpoint"},
			{"<leader>dc", "<cmd>lua require'dap'.continue()<cr>",  desc = "Debugger Continue" },
			{"<leader>di", "<cmd>lua require'dap'.step_into()<cr>",  desc = "Debugger Step Into" },
			{"<leader>do", "<cmd>lua require'dap'.step_over()<cr>",  desc = "Debugger Step Over" },
			{"<leader>dO", "<cmd>lua require'dap'.step_out()<cr>",  desc = "Debugger Step Out" },
			{"<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>",  desc = "Debugger Toggle Repl" },
			{"<leader>dl", "<cmd>lua require'dap'.run_last()<cr>",  desc = "Debugger Run Last" },
			{"<leader>du", "<cmd>lua require'dapui'.toggle()<cr>",  desc = "Debugger Toggle UI" },
			{"<leader>dt", "<cmd>lua require'dap'.terminate()<cr>",  desc = "Debugger Terminate" },
		},
		config = function()
			dap = require("dap")
			local dapui = require("dapui")
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

			-- add other configs here
			dapui.setup({
				expand_lines = true,
				icons = { expanded = "", collapsed = "", circular = "" },
				mappings = {
					-- Use a table to apply multiple mappings
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.33 },
							{ id = "breakpoints", size = 0.17 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						size = 0.33,
						position = "right",
					},
					{
						elements = {
							{ id = "repl", size = 0.45 },
							{ id = "console", size = 0.55 },
						},
						size = 0.27,
						position = "bottom",
					},
				},
				floating = {
					max_height = 0.9,
					max_width = 0.5, -- Floats will be treated as percentage of your screen.
					border = vim.g.border_chars, -- Border style. Can be 'single', 'double' or 'rounded'
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
			})

			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end

			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end

			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end
	}
}

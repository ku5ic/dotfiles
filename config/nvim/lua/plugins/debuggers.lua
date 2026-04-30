local function dap_continue()
	require("dap").continue()
end
local function dap_step_over()
	require("dap").step_over()
end
local function dap_step_into()
	require("dap").step_into()
end
local function dap_step_out()
	require("dap").step_out()
end

return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			{ "<F5>", dap_continue, desc = "Debug Continue" },
			{ "<F10>", dap_step_over, desc = "Debug Step Over" },
			{ "<F11>", dap_step_into, desc = "Debug Step Into" },
			{ "<F12>", dap_step_out, desc = "Debug Step Out" },
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{ "<leader>dc", dap_continue, desc = "Debug continue" },
			{ "<leader>ds", dap_step_over, desc = "Debug step over" },
			{ "<leader>di", dap_step_into, desc = "Debug step into" },
			{ "<leader>do", dap_step_out, desc = "Debug step out" },
			{
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "Open debug REPL",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate debug session",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run last debug session",
			},
			{
				"<leader>dh",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Debug hover",
			},
			{
				"<leader>dp",
				function()
					require("dap.ui.widgets").preview()
				end,
				desc = "Debug preview",
			},
			{
				"<leader>df",
				function()
					local widgets = require("dap.ui.widgets")
					widgets.centered_float(widgets.frames)
				end,
				desc = "Debug frames",
			},
			{
				"<leader>dv",
				function()
					local widgets = require("dap.ui.widgets")
					widgets.centered_float(widgets.scopes)
				end,
				desc = "Debug variables/scopes",
			},
		},
		config = function()
			local dap = require("dap")

			dap.adapters.php = {
				type = "executable",
				command = vim.fn.stdpath("data") .. "/mason/bin/php-debug-adapter",
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

			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
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

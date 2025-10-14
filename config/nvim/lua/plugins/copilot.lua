local icons = require("config.icons").icons

local prompts = require("utils.copilotchat").prompts

return {
	-- Copilot
	{
		"zbirenbaum/copilot.lua",
		-- cmd = "Copilot",
		build = ":Copilot auth",
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
		},
	},

	-- CopilotChat
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		version = "v4.7.4",
		-- branch = "canary", -- Use the canary branch if you want to test the latest features but it might be unstable	branch = "canary",
		build = "make tiktoken", -- Only on MacOS or Linux
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		opts = {
			headers = {
				user = icons.misc.User .. "Sinisa",
				assistant = icons.misc.Copilot .. "Copilot",
			},
			prompts = prompts,
			auto_follow_cursor = false, -- Don't follow the cursor after getting response
			-- model = "o3-mini",
			mappings = {
				-- Use tab for completion
				complete = {
					detail = "Use @<Tab> or /<Tab> for options.",
					insert = "<Tab>",
				},
				-- Close the chat
				close = {
					normal = "q",
					insert = "<C-c>",
				},
				-- Reset the chat buffer
				reset = {
					normal = "<C-x>",
					insert = "<C-x>",
				},
				-- Submit the prompt to Copilot
				submit_prompt = {
					normal = "<CR>",
					insert = "<C-CR>",
				},
				-- Accept the diff
				accept_diff = {
					normal = "<C-y>",
					insert = "<C-y>",
				},
				-- Yank the diff in the response to register
				yank_diff = {
					normal = "gmy",
				},
				-- Show the diff
				show_diff = {
					normal = "gmd",
				},
				-- Show the info
				show_info = {
					normal = "gmi",
				},
				-- Show the context
				show_context = {
					normal = "gmc",
				},
				-- Show help
				show_help = {
					normal = "gmh",
				},
			},
		},
		-- event = "VeryLazy",
	},
}

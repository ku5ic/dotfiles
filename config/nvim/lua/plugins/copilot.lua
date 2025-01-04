local mergeTables = require("utils").mergeTables
local prompts = {
	-- Code related prompts
	Code = {
		Explain = "Please explain how the following code works.",
		Review = "Please review the following code and provide suggestions for improvement.",
		Tests = "Please explain how the selected code works, then generate unit tests for it.",
		Refactor = "Please refactor the following code to improve its clarity and readability.",
		FixCode = "Please fix the following code to make it work as intended.",
		FixError = "Please explain the error in the following text and provide a solution.",
		BetterNamings = "Please provide better names for the following variables and functions.",
		Documentation = "Please provide documentation for the following code.",
		SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
		SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
	},
	-- Text related prompts
	Text = {
		Summarize = "Please summarize the following text.",
		Spelling = "Please correct any grammar and spelling errors in the following text.",
		Wording = "Please improve the grammar and wording of the following text.",
		Concise = "Please rewrite the following text to make it more concise.",
	},
}

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
		version = "v3.2.0",
		-- branch = "canary", -- Use the canary branch if you want to test the latest features but it might be unstable	branch = "canary",
		build = "make tiktoken", -- Only on MacOS or Linux
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		opts = {
			question_header = "## User ",
			answer_header = "## Copilot ",
			error_header = "## Error ",
			prompts = mergeTables(prompts.Code, prompts.Text),
			auto_follow_cursor = false, -- Don't follow the cursor after getting response
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
		config = function(_, opts)
			local chat = require("CopilotChat")
			local select = require("CopilotChat.select")
			-- Use unnamed register for the selection
			opts.selection = select.unnamed

			local user = vim.env.USER or "User"
			user = user:sub(1, 1):upper() .. user:sub(2)
			opts.question_header = "  " .. user .. " "
			opts.answer_header = "  Copilot "

			chat.setup(opts)

			vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
				chat.ask(args.args, { selection = select.visual })
			end, { nargs = "*", range = true })
		end,
		-- event = "VeryLazy",
		keys = {
			-- Show prompts actions with telescope
			{
				"<leader>ap",
				function()
					local actions = require("CopilotChat.actions").prompt_actions
					require("CopilotChat.integrations.telescope").pick(actions())
				end,
				desc = "CopilotChat - Prompt actions",
			},
			{
				"<leader>ap",
				function()
					local telescope = require("CopilotChat.integrations.telescope")
					local actions = require("CopilotChat.actions").prompt_actions
					local visual = require("CopilotChat.select").visual

					telescope.pick(actions({ selection = visual }))
				end,
				mode = "x",
				desc = "CopilotChat - Prompt actions",
			},
			-- Code related commands
			{ "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
			{ "<leader>at", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
			{ "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
			{ "<leader>aR", "<cmd>CopilotChatRefactor<cr>", desc = "CopilotChat - Refactor code" },
			{ "<leader>an", "<cmd>CopilotChatBetterNamings<cr>", desc = "CopilotChat - Better Naming" },
			-- Chat with Copilot in visual mode
			{
				"<leader>av",
				":CopilotChatVisual",
				mode = "x",
				desc = "CopilotChat - Open in vertical split",
			},
			-- Custom input for CopilotChat
			{
				"<leader>ai",
				function()
					local input = vim.trim(vim.fn.input("Ask Copilot: "))
					if input ~= "" then
						vim.cmd("CopilotChat " .. input)
					end
				end,
				desc = "CopilotChat - Ask input",
			},
			-- Generate commit message based on the git diff
			{
				"<leader>am",
				"<cmd>CopilotChatCommit<cr>",
				desc = "CopilotChat - Generate commit message for all changes",
			},
			-- Debug
			{ "<leader>ad", "<cmd>CopilotChatDebugInfo<cr>", desc = "CopilotChat - Debug Info" },
			-- Fix the issue with diagnostic
			{ "<leader>af", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "CopilotChat - Fix Diagnostic" },
			-- Clear buffer and chat history
			{ "<leader>al", "<cmd>CopilotChatReset<cr>", desc = "CopilotChat - Clear buffer and chat history" },
			-- Toggle Copilot Chat Vsplit
			{ "<leader>av", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
		},
	},
}

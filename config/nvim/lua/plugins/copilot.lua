--- Get all the changes in the git repository
---@param staged? boolean
---@return string
local function get_git_diff(staged)
	local cmd = staged and "git diff --staged" or "git diff"
	local handle = io.popen(cmd)
	if not handle then
		return ""
	end

	local result = handle:read("*a")
	handle:close()
	return result
end

local prompts = {
	-- Code related prompts
	Explain = "Please explain how the following code works.",
	Review = "Please review the following code and provide suggestions for improvement.",
	Tests = "Please explain how the selected code works, then generate unit tests for it.",
	Refactor = "Please refactor the following code to improve its clarity and readability.",
	FixCode = "Please fix the following code to make it work as intended.",
	BetterNamings = "Please provide better names for the following variables and functions.",
	Documentation = "Please provide documentation for the following code.",
	SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
	SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
	-- Text related prompts
	Summarize = "Please summarize the following text.",
	Spelling = "Please correct any grammar and spelling errors in the following text.",
	Wording = "Please improve the grammar and wording of the following text.",
	Concise = "Please rewrite the following text to make it more concise.",
}

return {
	-- Copilot
	{
		"github/copilot.vim",
		-- cmd = "Copilot",
		-- event = "InsertEnter",
		config = function()
			vim.g.copilot_filetypes = {
				["*"] = false,
				["css"] = true,
				["html"] = true,
				["javascript"] = true,
				["javascriptreact"] = true,
				["ruby"] = true,
				["python"] = true,
				["php"] = true,
				["lua"] = true,
				["typescript"] = true,
			}

			-- vim.g.copilot_node_command = "/Users/ku5ic/.nvm/versions/node/v16.19.1/bin/node"
			vim.g.copilot_no_tab_map = true
			vim.cmd([[highlight CopilotSuggestion guifg=#555555 ctermfg=8]])

			vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("")', { silent = true, expr = true })
		end,
	},

	-- Copilot chat
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
			{ "nvim-lua/plenary.nvim" },
		},
		opts = {
			show_help = "yes",
			prompts = prompts,
			debug = false, -- Set to true to see response from Github Copilot API. The log file will be in ~/.local/state/nvim/CopilotChat.nvim.log.
			disable_extra_info = "no", -- Disable extra information (e.g: system prompt, token count) in the response.
			hide_system_prompt = "yes", -- Show user prompts only and hide system prompts.
			-- proxy = "", -- Proxies requests via https or socks
		},
		build = function()
			vim.notify("Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim.")
		end,
		keys = {
			-- Show help actions with telescope
			{
				"<leader>cch",
				function()
					require("CopilotChat.code_actions").show_help_actions()
				end,
				desc = "CopilotChat - Help actions",
			},
			-- Show prompts actions with telescope
			{
				"<leader>ccp",
				function()
					require("CopilotChat.code_actions").show_prompt_actions()
				end,
				desc = "CopilotChat - Prompt actions",
			},
			{
				"<leader>ccp",
				":lua require('CopilotChat.code_actions').show_prompt_actions(true)<CR>",
				mode = "x",
				desc = "CopilotChat - Prompt actions",
			},
			-- Code related commands
			{ "<leader>cce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
			{ "<leader>cct", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
			{ "<leader>ccr", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
			{ "<leader>ccR", "<cmd>CopilotChatRefactor<cr>", desc = "CopilotChat - Refactor code" },
			{ "<leader>ccn", "<cmd>CopilotChatBetterNamings<cr>", desc = "CopilotChat - Better Naming" },
			-- Chat with Copilot in visual mode
			{
				"<leader>ccv",
				":CopilotChatVisual",
				mode = "x",
				desc = "CopilotChat - Open in vertical split",
			},
			{
				"<leader>ccx",
				":CopilotChatInPlace<cr>",
				mode = "x",
				desc = "CopilotChat - Run in-place code",
			},
			-- Custom input for CopilotChat
			{
				"<leader>cci",
				function()
					local input = vim.fn.input("Ask Copilot: ")
					if input ~= "" then
						vim.cmd("CopilotChat " .. input)
					end
				end,
				desc = "CopilotChat - Ask input",
			},
			-- Generate commit message based on the git diff
			{
				"<leader>ccm",
				function()
					local diff = get_git_diff()
					if diff ~= "" then
						vim.fn.setreg('"', diff)
						vim.cmd("CopilotChat Write commit message for the change with commitizen convention.")
					end
				end,
				desc = "CopilotChat - Generate commit message for all changes",
			},
			{
				"<leader>ccM",
				function()
					local diff = get_git_diff(true)
					if diff ~= "" then
						vim.fn.setreg('"', diff)
						vim.cmd("CopilotChat Write commit message for the change with commitizen convention.")
					end
				end,
				desc = "CopilotChat - Generate commit message for staged changes",
			},
			-- Quick chat with Copilot
			{
				"<leader>ccq",
				function()
					local input = vim.fn.input("Quick Chat: ")
					if input ~= "" then
						-- Copy all the lines to unnamed register
						vim.cmd('normal! ggVG"*y')
						vim.cmd("CopilotChat " .. input)
					end
				end,
				desc = "CopilotChat - Quick chat",
			},
			-- Debug
			{ "<leader>ccd", "<cmd>CopilotChatDebugInfo<cr>", desc = "CopilotChat - Debug Info" },
			-- Fix the issue with diagnostic
			{ "<leader>ccf", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "CopilotChat - Fix Diagnostic" },
			-- Clear buffer and chat history
			{ "<leader>ccl", "<cmd>CopilotChatReset<cr>", desc = "CopilotChat - Clear buffer and chat history" },
			-- Toggle Copilot Chat Vsplit
			{ "<leader>ccv", "<cmd>CopilotChatVsplitToggle<cr>", desc = "CopilotChat - Toggle Vsplit" },
		},
	},
}

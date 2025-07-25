local merge_tables = require("utils").merge_tables
local prompts = {
	Code = {
		Explain = [[
Explain the following code in simple, clear terms.
Cover the following aspects:
- What the code does overall
- The purpose of each function, block, or component
- The flow of data and control
- Any important logic, conditions, or iterations
- How the inputs affect the outputs
- Any side effects or asynchronous behavior
- Libraries or APIs being used and why
Keep the explanation concise but complete, as if teaching someone new to the codebase or technology.
		]],
		Review = [[
Review the following code and provide constructive feedback on:
- Code quality and readability
- Structure and organization
- Maintainability and scalability
- Adherence to best practices and coding standards
- Potential bugs, edge cases, or risky patterns
- Performance or efficiency issues
- Naming conventions and clarity
- Testability and code coverage (if relevant)
Suggest improvements where applicable and explain why those changes would benefit the code.
		]],
		Tests = [[
Write tests for the following code.
Ensure the tests:
- Cover all key functionality and logic branches
- Include edge cases and potential failure scenarios
- Use appropriate testing framework (e.g., Jest, Mocha, Vitest – follow the code’s context)
- Are clear, concise, and readable
- Follow good test naming conventions
- Include setup/teardown if needed
If tests already exist, review and improve them for completeness, reliability, and clarity.
After writing or improving the tests, briefly explain what is being tested and why it matters.
		]],
		Refactor = [[
Refactor the following code with the following goals in mind:
- Improve overall understanding and readability
- Optimize any inefficient logic
- Remove any repeated code (DRY principle)
- Make the code more concise where possible
- Split up any large or complex units (functions, components, blocks) into smaller, focused parts
- Rewrite conditional logic to improve readability and clarity
- Reformat the code to use a cleaner or more appropriate structure (e.g., object destructuring, map/filter, early returns, etc.)
After refactoring, explain what changes were made and why they improve the code.
        ]],
		Fix = [[
Analyze the following code and fix any errors that may be causing:
- Compilation or syntax failures
- Runtime exceptions or crashes
- Stack traces or error logs
- Misuse of libraries or APIs
- Incorrect or unsafe asynchronous behavior
- Missing variables, imports, or references
- Type mismatches or improper data usage
- Any other problems preventing the code from running correctly
After applying fixes, explain what the error was, what caused it, and how it was resolved.
		]],
		FixCode = [[
Review the following code and fix any issues with:
- Syntax errors
- Runtime errors or bugs
- Logical mistakes
- Incorrect use of language features or APIs
- Edge cases that might cause failures
- Missing error handling or defensive coding
- Potential issues with asynchronous code (e.g., missing await, unhandled promises)
- Improper or unclear naming that might lead to confusion
After fixing, explain what changes were made and why those fixes were necessary.
		]],
		BetterNamings = [[
Review the following code and improve the naming of:
- Variables
- Functions
- Parameters
- Constants
- Classes or components
Ensure that names are:
- Clear and self-explanatory
- Consistent with naming conventions (camelCase, PascalCase, etc.)
- Reflective of purpose and intent
- Free of ambiguity or misleading patterns
After renaming, explain what changes were made and how the new names improve the clarity and understanding of the code.
		]],
		Documentation = [[
Generate or improve documentation for the following code.
Include:
- Clear and concise descriptions of what each function, class, or component does
- Documentation for parameters (name, type, purpose)
- Return values (type and description)
- Any side effects, important notes, or caveats
- Examples of usage (if relevant)
Follow appropriate documentation conventions (e.g., JSDoc, TSDoc, docstrings) based on the language used.
The goal is to make the code easy to understand and use by other developers, even if they’re unfamiliar with it.
		]],
		WCAGRefactor = [[
Please refactor the following code to comply with WCAG 2.2 AA accessibility standards.
Focus on improving:
- Use of semantic HTML (headings, landmarks, buttons, etc.)
- Keyboard accessibility (focus order, interactive elements, navigation)
- Proper use of ARIA roles and attributes where necessary
- Color contrast compliance for text, UI components, and interactive elements
- Focus styles and management, ensuring visible focus and logical tab order
- Accessible forms with labels, error messages, instructions, and validation cues
- Use of alt text for meaningful images and skipping decorative ones
- Avoidance of time-based or motion-triggered issues unless properly handled
After refactoring, explain the specific accessibility issues that were resolved and how the changes align with WCAG 2.2 AA success criteria.
		]],
	},
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
		version = "v3.12.2",
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
			prompts = merge_tables(prompts.Code, prompts.Text),
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
		config = function(_, opts)
			local chat = require("CopilotChat")
			local select = require("CopilotChat.select")

			local function set_headers(opts)
				local user = (vim.env.USER or "User"):gsub("^%l", string.upper)
				opts.question_header = opts.question_header or ("  " .. user .. " ")
				opts.answer_header = opts.answer_header or "  Copilot "
			end

			local function create_visual_command()
				vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
					chat.ask(args.args, { selection = select.visual })
				end, { nargs = "*", range = true })
			end

			opts.selection = select.unnamed
			set_headers(opts)
			chat.setup(opts)
			create_visual_command()
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

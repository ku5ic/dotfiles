local M = {}

-- Tweak if needed
M.config = {
	include_diagnostics = true, -- add diagnostics summary
	include_git = false, -- add #git
}

local function safe_require()
	local ok, mod = pcall(require, "CopilotChat")
	if ok then
		return mod
	end
	return nil
end

-- A small registry of canned prompts you can expand at will.
M.prompts = {
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
Analyze the following code and fix any issues, including:
- Compilation or syntax errors
- Diagnostics reported by tools or language servers
- Runtime exceptions, crashes, or bugs
- Stack traces or error logs
- Misuse of libraries, APIs, or language features
- Incorrect or unsafe asynchronous behavior (e.g., missing await, unhandled promises)
- Missing variables, imports, or references
- Type mismatches or improper data usage
- Logical mistakes or edge cases that might cause failures
- Missing error handling or defensive coding
- Improper or unclear naming that might lead to confusion
After applying fixes, explain what the error was, what diagnostics were reported, what caused it, and how it was resolved.
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
- Free of ambiguity or misleading patterns
After renaming, explain what changes were made and how the new names improve the clarity and understanding of the code.
		]],
	Docs = [[
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
	WCAG = [[
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
	Summarize = "Please summarize the following text.",
	Spelling = "Please correct any grammar and spelling errors in the following text.",
	Wording = "Please improve the grammar and wording of the following text.",
	Concise = "Please rewrite the following text to make it more concise.",
}

-- Build a prompt using CopilotChat's context tags (no copying text)
-- selection_only=true  => prefer #selection; if not in visual mode, fall back to #buffer/#file
-- selection_only=false => always #buffer/#file
local function build_prompt(user_prompt, opts)
	opts = opts or {}
	local tags = {}

	-- selection vs buffer
	local m = vim.fn.mode()
	local visual = (m == "v" or m == "V" or m == "\22")

	if opts.selection_only and visual then
		table.insert(tags, "#selection")
	else
		table.insert(tags, "#buffer")
	end

	-- optional extras if you use them
	if M.config and M.config.include_diagnostics then
		table.insert(tags, "#diagnostics")
	end
	if M.config and M.config.include_git then
		table.insert(tags, "#git")
	end

	-- IMPORTANT: each tag on its own line, after an empty spacer line
	return table.concat({
		user_prompt or "",
		"",
		"Context:",
		table.concat(tags, "\n"),
	}, "\n")
end

local function try_commands(prompt)
	if prompt:find("\n") then
		return false
	end
	local esc = vim.fn.escape(prompt, [[\|"]])
	if pcall(function()
		vim.cmd("CopilotChat " .. esc)
	end) then
		return true
	end
	if pcall(function()
		vim.cmd("CopilotChatInline " .. esc)
	end) then
		return true
	end
	return false
end

function M.ask(user_prompt, opts)
	local composite = build_prompt(user_prompt, opts)

	-- Prefer the module API (handles multiline safely)
	local mod = safe_require()
	if mod and type(mod.ask) == "function" then
		local ok = pcall(mod.ask, composite, { window = { title = "CopilotChat" } })
		if ok then
			return true
		end
	end

	-- Only try Ex commands if there are no newlines
	if not composite:find("\n") and try_commands(composite) then
		return true
	end

	vim.notify("[CopilotChat] Unable to send prompt. Is the plugin loaded?", vim.log.levels.ERROR)
	return false
end

function M.prompt(name, opts)
	local p = M.prompts[name]
	if not p then
		vim.notify("[CopilotChat] Unknown prompt: " .. tostring(name), vim.log.levels.WARN)
		return
	end
	return M.ask(p, opts)
end

return M

--- CopilotChat prompt templates used by the local Neovim integration.
---
--- Purpose:
--- Centralizes reusable prompt text so callers can reference stable keys
--- (for example: "Review", "Fix", "Docs") instead of embedding large strings.
---
--- Non-obvious details:
--- - Most engineering-oriented prompts are prefixed with `BASE_CODE_RULES`
---   to enforce consistent constraints across tasks.
--- - Not all prompts use that base; some short text utilities remain plain.
--- - Prompt values are static strings and intentionally contain formatting
---   guidance to shape downstream LLM output.
---
--- Constraints:
--- - Key names in `M.prompts` act as public identifiers for callers; changing
---   them may break mappings in user commands, UI pickers, or config.
--- - Prompt content is policy-like configuration; edits can materially change
---   assistant behavior even when Lua logic is unchanged.
---
--- Side effects:
--- - This module has no runtime side effects beyond allocating in-memory
---   strings when required.
---
--- @class CopilotChatPromptsModule
--- @field prompts table<string, string> Named prompt templates consumed by CopilotChat flows.
---
--- @return CopilotChatPromptsModule
--- Module table containing prompt template mappings.
local M = {}

local BASE_CODE_RULES = [[
You are working on existing code, not writing from scratch.

Rules:
- Preserve existing behavior unless the prompt explicitly asks for behavior changes.
- Prefer the smallest correct change over broad rewrites.
- Do not invent missing requirements.
- Follow the existing language, framework, and project conventions visible in the code.
- Do not introduce new dependencies unless clearly justified by the existing context.
- If context is insufficient, state assumptions clearly.
- When suggesting changes, prioritize correctness, maintainability, and clarity over cleverness.
]]

-- Canned prompts library
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
	Review = BASE_CODE_RULES .. [[
Task:
Review the code and identify meaningful issues only.

Focus on:
- correctness and bugs
- maintainability
- readability where it affects understanding
- risky patterns
- testability
- performance only where it is realistically relevant

Do not focus on minor stylistic preferences unless they affect clarity or correctness.

Output format:
1. Summary
2. Findings by severity: high, medium, low
3. Recommended next actions

For each finding:
- state the issue
- explain why it matters
- suggest a concrete improvement
	]],
	Tests = BASE_CODE_RULES .. [[
Task:
Write or improve tests for the provided code.

Requirements:
- cover the main behavior and important branches
- include realistic edge cases
- prefer user visible behavior over implementation details
- use the existing test framework and conventions in the codebase
- avoid unnecessary mocking
- keep tests readable and focused

If tests already exist, improve gaps rather than rewriting them wholesale.

Output format:
1. Test plan
2. Added or improved test cases
3. Notes on important uncovered areas, if any
	]],
	Refactor = BASE_CODE_RULES .. [[
Task:
Refactor the code to improve clarity and maintainability without changing behavior.

Priorities:
- remove unnecessary complexity
- improve naming and structure
- reduce duplication where it clearly helps
- prefer early returns and simpler control flow when they improve readability

Constraints:
- preserve behavior and public interfaces unless explicitly requested otherwise
- avoid speculative abstractions
- avoid splitting code unless the result is clearly easier to understand and maintain
- do not optimize prematurely

Output format:
1. Refactor goals
2. Main changes made
3. Why these changes improve the code
4. Any tradeoffs
	]],
	Fix = BASE_CODE_RULES .. [[
Task:
Analyze the code and fix the actual issue with the smallest safe change.

Focus on:
- syntax or type errors
- failing diagnostics
- runtime bugs
- incorrect logic
- unsafe async behavior
- missing guards or error handling where required

Do not perform unrelated cleanup or refactors unless they are necessary to make the fix correct.

Output format:
1. Root cause
2. Applied fix
3. Why this resolves the issue
4. Any remaining risks or assumptions
]],
	RenameForClarity = [[
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
	Docs = BASE_CODE_RULES .. [[
Task:
Generate or improve documentation for the code.

Document:
- purpose and intent
- parameters and return values
- important side effects
- edge cases and constraints
- non obvious implementation details
- usage examples only when they add real value

Do not repeat what is already obvious from the code.
Follow the language appropriate documentation style.

Output format:
- updated documentation
- brief note describing what was clarified
]],
	WCAG = BASE_CODE_RULES .. [[
Task:
Review and refactor the code to improve accessibility toward WCAG 2.2 AA.

Priorities:
- semantic HTML first
- keyboard accessibility
- accessible names and labels
- focus visibility and logical navigation
- correct form semantics and errors
- appropriate ARIA only where native semantics are insufficient
- color contrast and non text contrast issues
- reduced motion or time based concerns where relevant

Do not add ARIA where native HTML already solves the problem.

Output format:
1. Accessibility issues found
2. Changes made
3. WCAG related rationale
4. Any issues that cannot be solved from code alone
	]],
	Summarize = "Please summarize the following text.",
	Spelling = "Please correct any grammar and spelling errors in the following text.",
	Wording = "Please improve the grammar and wording of the following text.",
	Concise = "Please rewrite the following text to make it more concise.",
}

return M

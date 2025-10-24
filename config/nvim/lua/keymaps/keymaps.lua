--[[
══════════════════════════════════════════════════════════════════════════════════
                           NEOVIM KEYMAP CONFIGURATION
══════════════════════════════════════════════════════════════════════════════════

This file contains a comprehensive, organized keymap structure following best practices:

■ ORGANIZATION PRINCIPLES:
  • Mnemonic patterns - Keys should be memorable (f = find, g = git, etc.)
  • Logical grouping - Related functions under common prefixes
  • Consistency - Similar operations use similar patterns
  • No conflicts - Each keymap is unique and non-overlapping

■ KEYMAP HIERARCHY:
  ├── Core Navigation & Editing (no prefix)
  ├── <leader>f - Find/File Operations (files, commands, help, format)
  ├── <leader>s - Search Operations (grep, todos, diagnostics)
  ├── <leader>g - Git Operations (status, commits, hunks)
  ├── <leader>w - Window Management (splits, resize, maximize)
  ├── <leader>t - Tabs & Toggles (tabs, explorer, terminal)
  ├── <leader>b - Buffer Operations (switch, delete, pin)
  ├── <leader>l - LSP Operations (rename, actions, diagnostics)
  ├── <leader>x - Diagnostics/Trouble (problems, quickfix)
  ├── <leader>d - Debug Operations (breakpoints, stepping)
  ├── <leader>a - AI/Copilot Operations (see keymaps/copilotchat.lua)
  ├── <leader>c - Copy Operations (file paths)
  └── <leader>n - Notifications & UI (dismiss, toggles)

■ QUICK REFERENCE:
  <leader>,     - Switch buffer (quick access)
  <leader>/     - Live grep search (quick access)  
  <leader><leader> - Reveal file in explorer (quick access)

══════════════════════════════════════════════════════════════════════════════════
--]]

local notify = require("notify")
local noice = require("noice")
local noice_lsp = require("noice.lsp")
local spectre = require("spectre")
local todo_comments = require("todo-comments")
local conform = require("conform")
local lint = require("lint")

local keymap = vim.keymap -- for conciseness
local opts = { noremap = true, silent = true } -- Silent keymap option

-- Utility function for setting keymaps with descriptions
local function map(mode, lhs, rhs, desc, options)
	opts = options or {}
	opts.desc = desc
	keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { noremap = true, silent = true }))
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ CORE NAVIGATION & EDITING
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Clear search highlights
map("n", "<leader>nh", ":nohl<CR>", "Clear search highlights")

-- Better up/down movement for wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Move down", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Move up", { expr = true })

-- Move lines with Alt+j/k
local move_mappings = {
	{ "n", "<A-j>", ":m .+1<CR>==", "Move line down" },
	{ "n", "<A-k>", ":m .-2<CR>==", "Move line up" },
	{ "i", "<A-j>", "<Esc>:m .+1<CR>==gi", "Move line down" },
	{ "i", "<A-k>", "<Esc>:m .-2<CR>==gi", "Move line up" },
	{ "v", "<A-j>", ":m '>+1<CR>gv=gv", "Move selection down" },
	{ "v", "<A-k>", ":m '<-2<CR>gv=gv", "Move selection up" },
}

for _, mapping in ipairs(move_mappings) do
	map(mapping[1], mapping[2], mapping[3], mapping[4])
end

-- Better indenting in visual mode
map("v", "<", "<gv", "Unindent and reselect")
map("v", ">", ">gv", "Indent and reselect")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ LSP NAVIGATION (Buffer-local, set via autocmd in LSP config)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- These keymaps are automatically set when LSP attaches to a buffer.
-- They remain in lsp.lua for proper buffer-local scoping:
--
-- gd          - Go to definition
-- gD          - Go to declaration
-- gr          - Go to references  
-- gi          - Go to implementation
-- gy          - Go to type definition
-- K           - Hover documentation
-- <C-k>       - Signature help (conflicts with window navigation, LSP takes priority)
-- <leader>lc  - Run code lens (only if LSP supports codelens)
--
-- Note: LSP action keymaps using <leader>l* prefix are defined below-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ WINDOW MANAGEMENT (<leader>w)
-- ═══════════════════════════════════════════════════════════════════════════════════

local window_mappings = {
	{ "<leader>wv", "<C-w>v", "Split window vertically" },
	{ "<leader>wh", "<C-w>s", "Split window horizontally" },
	{ "<leader>we", "<C-w>=", "Equalize window sizes" },
	{ "<leader>wc", ":close<CR>", "Close current window" },
	{ "<leader>wm", "<Cmd>MaximizerToggle<CR>", "Toggle maximize window" },
}

for _, mapping in ipairs(window_mappings) do
	map("n", mapping[1], mapping[2], mapping[3])
end

-- Window navigation with Ctrl+hjkl
map("n", "<C-h>", "<C-w>h", "Go to left window")
map("n", "<C-j>", "<C-w>j", "Go to bottom window")
map("n", "<C-k>", "<C-w>k", "Go to top window")
map("n", "<C-l>", "<C-w>l", "Go to right window")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ TAB MANAGEMENT (<leader>t)
-- ═══════════════════════════════════════════════════════════════════════════════════

local tab_mappings = {
	{ "<leader>tn", ":tabnew<CR>", "New tab" },
	{ "<leader>tc", ":tabclose<CR>", "Close tab" },
	{ "<leader>tj", ":tabnext<CR>", "Next tab" },
	{ "<leader>tk", ":tabprevious<CR>", "Previous tab" },
	{ "<leader>te", "<cmd>Neotree toggle<cr>", "Toggle file explorer" },
}

for _, mapping in ipairs(tab_mappings) do
	map("n", mapping[1], mapping[2], mapping[3])
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ BUFFER MANAGEMENT (<leader>b)
-- ═══════════════════════════════════════════════════════════════════════════════════

map("n", "<leader>bb", "<cmd>Telescope buffers show_all_buffers=true<cr>", "Switch buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")
map("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", "Pin buffer")
map("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", "Delete unpinned buffers")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ NOTIFICATIONS & UI (<leader>n)
-- ═══════════════════════════════════════════════════════════════════════════════════

map("n", "<leader>nn", function()
	notify.dismiss({ silent = true, pending = true })
end, "Dismiss notifications")

map("n", "<leader>np", "<cmd>Precognition toggle<cr>", "Toggle Precognition")

-- Noice commands
map("n", "<leader>nl", function()
	noice.cmd("last")
end, "Show last message")
map("n", "<leader>nH", function()
	noice.cmd("history")
end, "Show message history")
map("n", "<leader>na", function()
	noice.cmd("all")
end, "Show all messages")
map("n", "<leader>nd", function()
	noice.cmd("dismiss")
end, "Dismiss all messages")

-- Noice scroll in LSP hover docs
map({ "i", "n", "s" }, "<c-f>", function()
	if not noice_lsp.scroll(4) then
		return "<c-f>"
	end
end, "Scroll forward", { silent = true, expr = true })

map({ "i", "n", "s" }, "<c-b>", function()
	if not noice_lsp.scroll(-4) then
		return "<c-b>"
	end
end, "Scroll backward", { silent = true, expr = true })

-- Redirect cmdline
map("c", "<S-Enter>", function()
	noice.redirect(vim.fn.getcmdline())
end, "Redirect cmdline")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ QUICK ACCESS
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Quick access to commonly used functions
map("n", "<leader>,", "<cmd>Telescope buffers show_all_buffers=true<cr>", "Switch buffer (quick)")
map("n", "<leader>/", "<cmd>Telescope live_grep_args<cr>", "Search in files (quick)")

-- Neo-tree reveal current file
map("n", "<leader><leader>", "<cmd>Neotree reveal<cr>", "Reveal current file in explorer")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ FIND/FILE OPERATIONS (<leader>f)
-- ═══════════════════════════════════════════════════════════════════════════════════

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "Find files")
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", "Find recent files")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", "Find buffers")
map("n", "<leader>fc", "<cmd>Telescope commands<cr>", "Find commands")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", "Find help")
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", "Find keymaps")
map("n", "<leader>fm", function()
	conform.format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 1000,
	})
end, "Format file")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ SEARCH OPERATIONS (<leader>s)
-- ═══════════════════════════════════════════════════════════════════════════════════

map("n", "<leader>ss", "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Search in current buffer")
map("n", "<leader>sg", "<cmd>Telescope live_grep_args<cr>", "Search with live grep")
map("n", "<leader>sr", function()
	spectre.open()
end, "Search and replace")
map("n", "<leader>st", "<cmd>TodoTelescope<cr>", "Search todos")
map("n", "<leader>sd", "<cmd>Telescope diagnostics<cr>", "Search diagnostics")
map("n", "<leader>sa", "<cmd>Telescope autocommands<cr>", "Search autocommands")
map("n", "<leader>sc", "<cmd>Telescope command_history<cr>", "Search command history")
map("n", "<leader>sh", "<cmd>Telescope highlights<cr>", "Search highlights")
map("n", "<leader>sm", "<cmd>Telescope marks<cr>", "Search marks")
map("n", "<leader>so", "<cmd>Telescope vim_options<cr>", "Search options")
map("n", "<leader>sR", "<cmd>Telescope resume<cr>", "Resume last search")

-- Todo navigation
map("n", "]t", function()
	todo_comments.jump_next()
end, "Next todo comment")
map("n", "[t", function()
	todo_comments.jump_prev()
end, "Previous todo comment")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ GIT OPERATIONS (<leader>g)
-- ═══════════════════════════════════════════════════════════════════════════════════

map("n", "<leader>gg", "<cmd>LazyGit<cr>", "LazyGit")
map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", "Git status")
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", "Git commits")
map("n", "<leader>gb", "<cmd>Git blame <cr>", "Toggle git blame")
map("n", "<leader>gn", "<cmd>Gitsigns next_hunk<cr>", "Next git hunk")
map("n", "<leader>gp", "<cmd>Gitsigns prev_hunk<cr>", "Previous git hunk")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ LSP OPERATIONS (<leader>l)
-- ═══════════════════════════════════════════════════════════════════════════════════

map("n", "<leader>lr", vim.lsp.buf.rename, "LSP Rename")
map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP Code Action")
map("n", "<leader>lf", function()
	conform.format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 1000,
	})
end, "LSP Format")
map("n", "<leader>ld", function()
	vim.diagnostic.setloclist({ open = true })
end, "LSP Diagnostics to location list")
map("n", "<leader>ll", function()
	lint.try_lint()
end, "Lint current file")
map("n", "<leader>li", "<cmd>LspInfo<cr>", "LSP Info")

-- LSP Workspace management (moved from <leader>w to <leader>lw for LSP grouping)
map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, "LSP Add workspace folder")
map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, "LSP Remove workspace folder")
map("n", "<leader>lwl", function()
	print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, "LSP List workspace folders")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ DIAGNOSTICS/TROUBLE (<leader>x)
-- ═══════════════════════════════════════════════════════════════════════════════════

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Show all diagnostics")
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Show document diagnostics")
map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", "Show symbols")
map("n", "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "Show LSP references")
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Show location list")
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", "Show quickfix list")

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ DEBUG OPERATIONS (<leader>d)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Debug control
map("n", "<F5>", "<cmd>lua require'dap'.continue()<cr>", "Debug Continue")
map("n", "<F10>", "<cmd>lua require'dap'.step_over()<cr>", "Debug Step Over")
map("n", "<F11>", "<cmd>lua require'dap'.step_into()<cr>", "Debug Step Into")
map("n", "<F12>", "<cmd>lua require'dap'.step_out()<cr>", "Debug Step Out")

-- Debug actions
map("n", "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle breakpoint")
map("n", "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", "Debug continue")
map("n", "<leader>ds", "<cmd>lua require'dap'.step_over()<cr>", "Debug step over")
map("n", "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", "Debug step into")
map("n", "<leader>do", "<cmd>lua require'dap'.step_out()<cr>", "Debug step out")
map("n", "<leader>dr", "<cmd>lua require'dap'.repl.open()<cr>", "Open debug REPL")
map("n", "<leader>dt", "<cmd>lua require'dap'.terminate()<cr>", "Terminate debug session")
map("n", "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>", "Run last debug session")

-- Debug UI
map("n", "<leader>dh", "<cmd>lua require'dap.ui.widgets'.hover()<cr>", "Debug hover")
map("n", "<leader>dp", "<cmd>lua require'dap.ui.widgets'.preview()<cr>", "Debug preview")
map(
	"n",
	"<leader>df",
	"<cmd>lua require'dap.ui.widgets'.centered_float(require'dap.ui.widgets'.frames)<cr>",
	"Debug frames"
)
map(
	"n",
	"<leader>dv",
	"<cmd>lua require'dap.ui.widgets'.centered_float(require'dap.ui.widgets'.scopes)<cr>",
	"Debug variables/scopes"
)

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ AI/COPILOT OPERATIONS (<leader>a)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- AI keymaps are defined in keymaps/copilotchat.lua
-- See that file for the complete list of AI operations

-- ═══════════════════════════════════════════════════════════════════════════════════
-- ■ COPY FILE PATH (<leader>c)
-- ═══════════════════════════════════════════════════════════════════════════════════
map("n", "<leader>cP", "<cmd>CopyPath<cr>", "Copy Full File Path")
map("n", "<leader>cp", "<cmd>CopyRelPath<cr>", "Copy Relative File Path")

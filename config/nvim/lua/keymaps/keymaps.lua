-- Neovim keymap configuration
-- See CLAUDE.md for keymap prefix conventions
--
-- Plugin-specific keymaps live with their plugin specs (lazy `keys = {...}`)
-- so removing a plugin removes its mappings cleanly. Built-ins, telescope/git
-- (which trigger lazy loading via <cmd> form), LSP, Trouble, and Neovide
-- bindings stay here.

local keymap = vim.keymap

-- Utility function for setting keymaps with descriptions.
-- Deliberately does not close over a shared opts table to avoid mutation bugs.
local function map(mode, lhs, rhs, desc, extra_opts)
	local opts = vim.tbl_extend("force", { noremap = true, silent = true }, extra_opts or {})
	opts.desc = desc
	keymap.set(mode, lhs, rhs, opts)
end

-- Core navigation & editing

map("n", "<leader>nh", ":nohl<CR>", "Clear search highlights")

-- Better up/down movement for wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Move down", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Move up", { expr = true })

-- Move lines with Alt+j/k
map("n", "<A-j>", ":m .+1<CR>==", "Move line down")
map("n", "<A-k>", ":m .-2<CR>==", "Move line up")
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi", "Move line down")
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi", "Move line up")
map("v", "<A-j>", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "<A-k>", ":m '<-2<CR>gv=gv", "Move selection up")

-- Better indenting in visual mode
map("v", "<", "<gv", "Unindent and reselect")
map("v", ">", ">gv", "Indent and reselect")

-- LSP navigation (buffer-local, set via autocmd in LSP config)
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
-- <C-k>       - Signature help
-- <leader>lc  - Run code lens (only if LSP supports codelens)
--
-- Note: LSP action keymaps using <leader>l* prefix are defined below

-- Window management (<leader>w)
map("n", "<leader>wv", "<C-w>v", "Split window vertically")
map("n", "<leader>wh", "<C-w>s", "Split window horizontally")
map("n", "<leader>we", "<C-w>=", "Equalize window sizes")
map("n", "<leader>wc", ":close<CR>", "Close current window")
map("n", "<leader>wm", "<Cmd>MaximizerToggle<CR>", "Toggle maximize window")

-- Tab management (<leader>t)
map("n", "<leader>tn", ":tabnew<CR>", "New tab")
map("n", "<leader>tc", ":tabclose<CR>", "Close tab")
map("n", "<leader>tj", ":tabnext<CR>", "Next tab")
map("n", "<leader>tk", ":tabprevious<CR>", "Previous tab")
map("n", "<leader>te", "<cmd>Neotree toggle<cr>", "Toggle file explorer")

-- Buffer management (<leader>b)
map("n", "<leader>bb", "<cmd>Telescope buffers show_all_buffers=true<cr>", "Switch buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")
map("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", "Pin buffer")
map("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", "Delete unpinned buffers")

-- Quick access
map("n", "<leader>,", "<cmd>Telescope buffers show_all_buffers=true<cr>", "Switch buffer (quick)")
map("n", "<leader>/", "<cmd>Telescope live_grep_args<cr>", "Search in files (quick)")

-- Neo-tree reveal current file
map("n", "<leader><leader>", "<cmd>Neotree reveal<cr>", "Reveal current file in explorer")

-- Find/file operations (<leader>f)
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "Find files")
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", "Find recent files")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", "Find buffers")
map("n", "<leader>fc", "<cmd>Telescope commands<cr>", "Find commands")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", "Find help")
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", "Find keymaps")
-- <leader>fm (Format file) lives in plugins/formatting.lua

-- Search operations (<leader>s)
map("n", "<leader>ss", "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Search in current buffer")
map("n", "<leader>sg", "<cmd>Telescope live_grep_args<cr>", "Search with live grep")
-- <leader>sr (Search and replace) lives in plugins/editor.lua under nvim-spectre
map("n", "<leader>st", "<cmd>TodoTelescope<cr>", "Search todos")
map("n", "<leader>sd", "<cmd>Telescope diagnostics<cr>", "Search diagnostics")
map("n", "<leader>sa", "<cmd>Telescope autocommands<cr>", "Search autocommands")
map("n", "<leader>sc", "<cmd>Telescope command_history<cr>", "Search command history")
map("n", "<leader>sh", "<cmd>Telescope highlights<cr>", "Search highlights")
map("n", "<leader>sm", "<cmd>Telescope marks<cr>", "Search marks")
map("n", "<leader>so", "<cmd>Telescope vim_options<cr>", "Search options")
map("n", "<leader>sR", "<cmd>Telescope resume<cr>", "Resume last search")

-- Todo navigation: ]t / [t live in plugins/editor.lua under todo-comments.nvim

-- Git operations (<leader>g)
map("n", "<leader>gg", "<cmd>LazyGit<cr>", "LazyGit")
map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", "Git status")
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", "Git commits")
map("n", "<leader>gb", "<cmd>Git blame <cr>", "Toggle git blame")
map("n", "<leader>gn", "<cmd>Gitsigns next_hunk<cr>", "Next git hunk")
map("n", "<leader>gp", "<cmd>Gitsigns prev_hunk<cr>", "Previous git hunk")

-- LSP operations (<leader>l)
map("n", "<leader>lr", vim.lsp.buf.rename, "LSP Rename")
map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP Code Action")
-- <leader>lf (LSP Format) lives in plugins/formatting.lua
map("n", "<leader>ld", function()
	vim.diagnostic.setloclist({ open = true })
end, "LSP Diagnostics to location list")
-- <leader>ll (Lint current file) lives in plugins/linting.lua
map("n", "<leader>li", "<cmd>LspInfo<cr>", "LSP Info")

-- LSP Workspace management
map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, "LSP Add workspace folder")
map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, "LSP Remove workspace folder")
map("n", "<leader>lwl", function()
	print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, "LSP List workspace folders")

-- Diagnostics/Trouble (<leader>x)
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Show all diagnostics")
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Show document diagnostics")
map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", "Show symbols")
map("n", "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "Show LSP references")
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Show location list")
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", "Show quickfix list")

-- Debug operations (<leader>d) and F5/F10/F11/F12 live in plugins/debuggers.lua

-- AI/Copilot operations (<leader>a) live in keymaps/copilotchat.lua

-- Notifications & UI (<leader>n)
-- Sub-mappings live in their owning plugin specs:
--   <leader>nn -> plugins/ui.lua (nvim-notify)
--   <leader>nl/nH/na/nd -> plugins/ui.lua (noice.nvim)
--   <leader>np -> plugins/editor.lua (precognition.nvim)
-- <c-f>/<c-b> noice scrolls and <S-Enter> redirect also live in plugins/ui.lua.

-- Copy file path (<leader>c)
map("n", "<leader>cP", "<cmd>CopyPath<cr>", "Copy Full File Path")
map("n", "<leader>cp", "<cmd>CopyRelPath<cr>", "Copy Relative File Path")

-- Neovide
map("n", "<D-v>", '"+p', "Neovide paste")
map("i", "<D-v>", "<C-r>+", "Neovide paste")
map("v", "<D-v>", '"+p', "Neovide paste")
map("v", "<D-c>", '"+y', "Neovide copy")

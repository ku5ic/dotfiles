-- Neovim keymap configuration
-- See CLAUDE.md for keymap prefix conventions
--
-- Plugin-specific keymaps live with their plugin specs (lazy `keys = {...}`)
-- so removing a plugin removes its mappings cleanly. Built-ins, snacks/git
-- (which trigger lazy loading via Lua functions), LSP, Trouble, and Neovide
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

-- LSP navigation reference
--
-- Neovim 0.10+ sets these automatically on LspAttach (no custom mapping needed):
--   K      - Hover documentation
--   grr    - References
--   gri    - Implementation
--   grn    - Rename
--   gra    - Code action
--   grt    - Type definition
--   grx    - Run codelens
--   C-]    - Go to definition (via LSP tagfunc)
--
-- Custom buffer-local (set in lsp.lua):
--   <leader>lk  - Signature help
--   <leader>lc  - Run codelens (only if server supports it)
--
-- Custom global (defined below under <leader>l*):

-- Window management (<leader>w)
map("n", "<leader>wv", "<C-w>v", "Split window vertically")
map("n", "<leader>wh", "<C-w>s", "Split window horizontally")
map("n", "<leader>we", "<C-w>=", "Equalize window sizes")
map("n", "<leader>wc", ":close<CR>", "Close current window")
-- Open current buffer in a new full-screen tab; close that tab to restore the original layout.
-- State is derived from actual window/tab count so it self-heals if the tab is closed another way.
map("n", "<leader>wm", function()
  if vim.fn.winnr("$") == 1 and vim.fn.tabpagenr("$") > 1 then
    vim.cmd("tabclose")
  else
    vim.cmd("tab split")
  end
end, "Toggle maximize window")

-- Tab management (<leader>t)
map("n", "<leader>tn", ":tabnew<CR>", "New tab")
map("n", "<leader>tc", ":tabclose<CR>", "Close tab")
map("n", "<leader>tj", ":tabnext<CR>", "Next tab")
map("n", "<leader>tk", ":tabprevious<CR>", "Previous tab")
map("n", "<leader>te", function()
  Snacks.explorer()
end, "Toggle file explorer")

-- Buffer management (<leader>b)
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")
map("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", "Pin buffer")
map("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", "Delete unpinned buffers")

-- Quick access (snacks defaults)
map("n", "<leader><space>", function()
  Snacks.picker.smart()
end, "Smart find")
map("n", "<leader>,", function()
  Snacks.picker.buffers()
end, "Buffers")
map("n", "<leader>/", function()
  Snacks.picker.grep()
end, "Search in files")
map("n", "<leader>:", function()
  Snacks.picker.command_history()
end, "Command history")

-- Explorer (<leader>e / <leader>E)
map("n", "<leader>e", function()
  Snacks.explorer()
end, "File explorer")
map("n", "<leader>E", function()
  Snacks.explorer.reveal()
end, "Reveal file in explorer")

-- Find/file operations (<leader>f)
map("n", "<leader>ff", function()
  Snacks.picker.files()
end, "Find files")
map("n", "<leader>fr", function()
  Snacks.picker.recent()
end, "Find recent files")
map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, "Find buffers")
map("n", "<leader>fc", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, "Find config files")
map("n", "<leader>fg", function()
  Snacks.picker.git_files()
end, "Find git files")
map("n", "<leader>fp", function()
  Snacks.picker.projects()
end, "Find projects")
-- <leader>fm (Format file) lives in plugins/formatting.lua

-- Search operations (<leader>s)
map("n", "<leader>sb", function()
  Snacks.picker.lines()
end, "Search buffer lines")
map("n", "<leader>sB", function()
  Snacks.picker.grep_buffers()
end, "Grep open buffers")
map("n", "<leader>sg", function()
  Snacks.picker.grep()
end, "Search with grep")
map("n", "<leader>sw", function()
  Snacks.picker.grep_word()
end, "Search word under cursor")
-- <leader>sr (Search and replace) lives in plugins/editor.lua under grug-far.nvim
map("n", "<leader>st", function()
  Snacks.picker.todo_comments()
end, "Search todos")
map("n", "<leader>sd", function()
  Snacks.picker.diagnostics()
end, "Search diagnostics")
map("n", "<leader>sD", function()
  Snacks.picker.diagnostics_buffer()
end, "Buffer diagnostics")
map("n", "<leader>sa", function()
  Snacks.picker.autocmds()
end, "Search autocommands")
map("n", "<leader>sc", function()
  Snacks.picker.command_history()
end, "Search command history")
map("n", "<leader>sC", function()
  Snacks.picker.commands()
end, "Search commands")
map("n", "<leader>sh", function()
  Snacks.picker.help()
end, "Search help")
map("n", "<leader>sH", function()
  Snacks.picker.highlights()
end, "Search highlights")
map("n", "<leader>si", function()
  Snacks.picker.icons()
end, "Search icons")
map("n", "<leader>sj", function()
  Snacks.picker.jumps()
end, "Search jumps")
map("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, "Search keymaps")
map("n", "<leader>sl", function()
  Snacks.picker.loclist()
end, "Search location list")
map("n", "<leader>sm", function()
  Snacks.picker.marks()
end, "Search marks")
map("n", "<leader>sM", function()
  Snacks.picker.man()
end, "Search man pages")
map("n", "<leader>sp", function()
  Snacks.picker.lazy()
end, "Search plugin specs")
map("n", "<leader>sq", function()
  Snacks.picker.qflist()
end, "Search quickfix list")
map("n", "<leader>ss", function()
  Snacks.picker.lsp_symbols()
end, "LSP symbols")
map("n", "<leader>sS", function()
  Snacks.picker.lsp_workspace_symbols()
end, "LSP workspace symbols")
map("n", "<leader>su", function()
  Snacks.picker.undo()
end, "Search undo history")
map("n", "<leader>sR", function()
  Snacks.picker.resume()
end, "Resume last search")
map("n", '<leader>s"', function()
  Snacks.picker.registers()
end, "Search registers")
map("n", "<leader>s/", function()
  Snacks.picker.search_history()
end, "Search history")

-- Todo navigation: ]t / [t live in plugins/editor.lua under todo-comments.nvim

-- Git operations (<leader>g)
map("n", "<leader>gg", function()
  Snacks.lazygit.open()
end, "LazyGit")
map("n", "<leader>gb", function()
  Snacks.picker.git_branches()
end, "Git branches")
map("n", "<leader>gB", function()
  Snacks.gitbrowse()
end, "Git browse (open in browser)")
map("n", "<leader>gc", function()
  Snacks.picker.git_log()
end, "Git log")
map("n", "<leader>gd", function()
  Snacks.picker.git_diff()
end, "Git diff hunks")
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, "Git log (current file)")
map("n", "<leader>gi", function()
  Snacks.picker.gh_issue()
end, "GitHub issues (open)")
map("n", "<leader>gI", function()
  Snacks.picker.gh_issue({ state = "all" })
end, "GitHub issues (all)")
map("n", "<leader>gl", function()
  Snacks.picker.git_log_line()
end, "Git log (current line)")
map("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, "Git log (full)")
map("n", "]h", "<cmd>Gitsigns next_hunk<cr>", "Next git hunk")
map("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", "Previous git hunk")
map("n", "<leader>gn", "<cmd>Gitsigns next_hunk<cr>", "Next git hunk")
map("n", "<leader>gp", function()
  Snacks.picker.gh_pr()
end, "GitHub PRs (open)")
map("n", "<leader>gP", function()
  Snacks.picker.gh_pr({ state = "all" })
end, "GitHub PRs (all)")
map("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, "Git status")
map("n", "<leader>gS", function()
  Snacks.picker.git_stash()
end, "Git stash")

-- LSP operations (<leader>l)
map("n", "<leader>lr", vim.lsp.buf.rename, "LSP Rename")
map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP Code Action")
-- <leader>lf (LSP Format) lives in plugins/formatting.lua
map("n", "<leader>ld", function()
  vim.diagnostic.setloclist({ open = true })
end, "LSP Diagnostics to location list")
-- <leader>ll (Lint current file) lives in plugins/linting.lua
map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", "LSP Info")

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
map("n", "<leader>nN", function()
  Snacks.picker.notifications()
end, "Notification history")
-- Sub-mappings live in their owning plugin specs:
--   <leader>nn -> plugins/snacks.lua (snacks.notifier dismiss)
--   <leader>nl/nH/na/nd -> plugins/ui.lua (noice.nvim)
--   <leader>np -> plugins/editor.lua (precognition.nvim)
-- <c-f>/<c-b> noice scrolls and <S-Enter> redirect also live in plugins/ui.lua.

-- UI / colorscheme (<leader>u)
-- Toggles registered via snacks.toggle in plugins/snacks.lua init (VeryLazy).
map("n", "<leader>uC", function()
  Snacks.picker.colorschemes()
end, "Colorschemes")

-- Copy file path (<leader>c)
map("n", "<leader>cP", "<cmd>CopyPath<cr>", "Copy Full File Path")
map("n", "<leader>cp", "<cmd>CopyRelPath<cr>", "Copy Relative File Path")

-- Neovide
map("n", "<D-v>", '"+p', "Neovide paste")
map("i", "<D-v>", "<C-r>+", "Neovide paste")
map("v", "<D-v>", '"+p', "Neovide paste")
map("v", "<D-c>", '"+y', "Neovide copy")

-- Open file or URL under cursor with gx
vim.keymap.set("n", "gx", function()
  local target = vim.fn.expand("<cfile>")
  if target:match("^https?://") or target:match("^mailto:") then
    vim.ui.open(target)
  else
    if not target:match("^/") then
      target = vim.fn.expand("%:p:h") .. "/" .. target
    end
    vim.cmd.edit(vim.fn.fnamemodify(target, ":p"))
  end
end, { desc = "Open file or URL under cursor" })

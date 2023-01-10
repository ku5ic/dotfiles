-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness
local opts = { silent = true } -- Silent keymap option

---------------------
-- General Keymaps
---------------------

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", opts)

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", opts) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", opts) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", opts) -- make split windows equal width & height
keymap.set("n", "<leader>sx", ":close<CR>", opts) -- close current split window

keymap.set("n", "<leader>to", ":tabnew<CR>", opts) -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>", opts) -- close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>", opts) --  go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>", opts) --  go to previous tab

----------------------
-- Plugin Keybinds
----------------------

-- vim-maximizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>", opts) -- toggle split window maximization

-- nvim-tree
keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", opts) -- toggle file explorer
keymap.set("n", "<leader>tf", ":NvimTreeFindFile<CR>", opts) -- focus current file on file in file explorer

-- telescope
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts) -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", opts) -- find string in current working directory as you type
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", opts) -- find string under cursor in current working directory
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", opts) -- list open buffers in current neovim instance
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", opts) -- list available help tags

-- telescope lsp diagnostics
keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", opts) -- list available diagnostics

-- telescope git commands
keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", opts) -- list all git commits (use <cr> to checkout) ["gc" for git commits]
keymap.set("n", "<leader>gfc", "<cmd>Telescope git_bcommits<cr>", opts) -- list git commits for current file/buffer (use <cr> to checkout) ["gfc" for git file commits]
keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", opts) -- list git branches (use <cr> to checkout) ["gb" for git branch]
keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>", opts) -- list current changes per file with diff preview ["gs" for git status]

-- restart lsp server
keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

-- DAP
keymap.set("n", "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", opts)
keymap.set("n", "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", opts)
keymap.set("n", "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", opts)
keymap.set("n", "<leader>do", "<cmd>lua require'dap'.step_over()<cr>", opts)
keymap.set("n", "<leader>dO", "<cmd>lua require'dap'.step_out()<cr>", opts)
keymap.set("n", "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>", opts)
keymap.set("n", "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>", opts)
keymap.set("n", "<leader>du", "<cmd>lua require'dapui'.toggle()<cr>", opts)
keymap.set("n", "<leader>dt", "<cmd>lua require'dap'.terminate()<cr>", opts)

-- move lines
local move_opts = { noremap = true, silent = true }

keymap.set("n", "<A-j>", ":m .+1<CR>==", move_opts)
keymap.set("n", "<A-k>", ":m .-2<CR>==", move_opts)

keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi", move_opts)
keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi", move_opts)

keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", move_opts)
keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", move_opts)

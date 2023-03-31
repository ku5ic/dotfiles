
-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness
local opts = { noremap = true, silent = true } -- Silent keymap option

local set_desc = require("utils").set_desc
---------------------
-- General Keymaps
---------------------

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl <CR>", set_desc(opts, { desc = "Clear search highlights" }))

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", set_desc(opts, { desc = "Split Window Vertically" }))
keymap.set("n", "<leader>sh", "<C-w>s", set_desc(opts, { desc = "Split Window Horizontally" }))
keymap.set("n", "<leader>se", "<C-w>=", set_desc(opts, { desc = "Make Split Window Equal Width & Height" }))
keymap.set("n", "<leader>sx", ":close <CR>", set_desc(opts, { desc = "Close Current Window" }))

keymap.set("n", "<leader>to", ":tabnew <CR>", set_desc(opts, { desc = "Open New Tab" }))
keymap.set("n", "<leader>tx", ":tabclose <CR>", set_desc(opts, { desc = "Close Current Tab" }))
keymap.set("n", "<leader>tn", ":tabn <CR>", set_desc(opts, { desc = "Go To Next Tab" }))
keymap.set("n", "<leader>tp", ":tabp <CR>", set_desc(opts, { desc = "Go To Previous Tab" }))

-- move lines
local move_opts = { noremap = true, silent = true }

keymap.set("n", "<A-j>", ":m .+1<CR>==", set_desc(move_opts, { desc = "Move Line Down" }))
keymap.set("n", "<A-k>", ":m .-2<CR>==", set_desc(move_opts, { desc = "Move Line Up" }))

keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi", set_desc(move_opts, { desc = "Move Line Down" }))
keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi", set_desc(move_opts, { desc = "Move Line Up" }))

keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", set_desc(move_opts, { desc = "Move Selection Down" }))
keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", set_desc(move_opts, { desc = "Move Selection Up" }))

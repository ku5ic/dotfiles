-- Set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness
local opts = { noremap = true, silent = true } -- Silent keymap option

-- Utility function for setting keymaps with descriptions
local function map(mode, lhs, rhs, desc)
	keymap.set(mode, lhs, rhs, require("utils").set_desc(opts, { desc = desc }))
end

-- General Keymaps
map("n", "<leader>nh", ":nohl <CR>", "Clear search highlights")

-- Window management
local window_mappings = {
	{ "<leader>sv", "<C-w>v", "Split Window Vertically" },
	{ "<leader>sh", "<C-w>s", "Split Window Horizontally" },
	{ "<leader>se", "<C-w>=", "Make Split Window Equal Width & Height" },
	{ "<leader>sx", ":close <CR>", "Close Current Window" },
	{ "<leader>to", ":tabnew <CR>", "Open New Tab" },
	{ "<leader>tx", ":tabclose <CR>", "Close Current Tab" },
	{ "<leader>tn", ":tabn <CR>", "Go To Next Tab" },
	{ "<leader>tp", ":tabp <CR>", "Go To Previous Tab" },
}

for _, mapping in ipairs(window_mappings) do
	map("n", mapping[1], mapping[2], mapping[3])
end

-- Move lines
local move_mappings = {
	{ "n", "<A-j>", ":m .+1<CR>==", "Move Line Down" },
	{ "n", "<A-k>", ":m .-2<CR>==", "Move Line Up" },
	{ "i", "<A-j>", "<Esc>:m .+1<CR>==gi", "Move Line Down" },
	{ "i", "<A-k>", "<Esc>:m .-2<CR>==gi", "Move Line Up" },
	{ "v", "<A-j>", ":m '>+1<CR>gv=gv", "Move Selection Down" },
	{ "v", "<A-k>", ":m '<-2<CR>gv=gv", "Move Selection Up" },
}

for _, mapping in ipairs(move_mappings) do
	map(mapping[1], mapping[2], mapping[3], mapping[4])
end

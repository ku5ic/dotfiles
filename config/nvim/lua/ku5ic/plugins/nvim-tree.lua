-- import nvim-tree plugin safely
local setup, nvimtree = pcall(require, "nvim-tree")
if not setup then
	return
end

local function open_nvim_tree(data)
	-- is real file
	local is_real_file = vim.fn.filereadable(data.file) == 1

	-- buffer is a [No Name]
	local is_no_name = data.file == "" and vim.bo[data.buf].buftype == ""

	-- buffer is a directory
	local is_directory = vim.fn.isdirectory(data.file) == 1

	-- change to the directory
	-- open the tree
	if is_directory then
		vim.cmd.cd(data.file)
		require("nvim-tree.api").tree.open()
	end

	-- open the tree and find the file
	if is_real_file then
		require("nvim-tree.api").tree.toggle({ focus = false, find_file = true })
		return
	end

	-- do nothing
	if is_no_name then
		return
	end
end

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

-- recommended settings from nvim-tree documentation
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- change color for arrows in tree to light blue
vim.cmd([[ highlight NvimTreeIndentMarker guifg=#3FC5FF ]])

-- configure nvim-tree
nvimtree.setup({
	-- change folder arrow icons
	renderer = {
		icons = {
			glyphs = {
				folder = {
					arrow_open = "", -- arrow when folder is closed
					arrow_closed = "", -- arrow when folder is open
				},
			},
		},
	},
	-- disable window_picker for
	-- explorer to work well with
	-- window splits
	actions = {
		open_file = {
			window_picker = {
				enable = false,
			},
		},
	},
	view = {
		adaptive_size = true,
		width = 40,
	},
	-- 	git = {
	-- 		ignore = false,
	-- 	},
})

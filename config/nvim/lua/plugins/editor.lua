return {
	-- file explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		keys = {
			{ "<C-enter>",   "<cmd>Neotree toggle<cr>", desc = "Toggle NeoTree" },
			{ "<C-S-enter>", "<cmd>NeoTreeReveal<cr>",  desc = "Reveal In NeoTree" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
	},
	-- search/replace in multiple files
	{
		"windwp/nvim-spectre",
		-- stylua: ignore
		keys = {
			{ "<leader>sr", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
		},
	},
	-- git signs
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			on_attach = function(bufnr)
				local function map(mode, lhs, rhs, opts)
					opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
					vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
				end

				-- Navigation
				map("n", "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true })
				map("n", "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true })

				-- Actions
				map("n", "<leader>hs", ":Gitsigns stage_hunk<CR>")
				map("v", "<leader>hs", ":Gitsigns stage_hunk<CR>")
				map("n", "<leader>hr", ":Gitsigns reset_hunk<CR>")
				map("v", "<leader>hr", ":Gitsigns reset_hunk<CR>")
				map("n", "<leader>hS", "<cmd>Gitsigns stage_buffer<CR>")
				map("n", "<leader>hu", "<cmd>Gitsigns undo_stage_hunk<CR>")
				map("n", "<leader>hR", "<cmd>Gitsigns reset_buffer<CR>")
				map("n", "<leader>hp", "<cmd>Gitsigns preview_hunk<CR>")
				map("n", "<leader>hb", '<cmd>lua require"gitsigns".blame_line{full=true}<CR>')
				map("n", "<leader>tb", "<cmd>Gitsigns toggle_current_line_blame<CR>")
				map("n", "<leader>hd", "<cmd>Gitsigns diffthis<CR>")
				map("n", "<leader>hD", '<cmd>lua require"gitsigns".diffthis("~")<CR>')
				map("n", "<leader>td", "<cmd>Gitsigns toggle_deleted<CR>")

				-- Text object
				map("o", "ih", ":<C-U>Gitsigns select_hunk<CR>")
				map("x", "ih", ":<C-U>Gitsigns select_hunk<CR>")
			end,
		},
	},

	-- fuzzy finder
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.3",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		-- version = false, -- telescope did only one release, so use HEAD for now
		keys = {
			{ "<leader>,",  "<cmd>Telescope buffers show_all_buffers=true<cr>", desc = "Switch Buffer" },
			{ "<leader>/",  "<cmd>Telescope live_grep<cr>",                     desc = "Find in Files (Grep)" },
			{ "<leader>:",  "<cmd>Telescope command_history<cr>",               desc = "Command History" },
			-- find
			{ "<leader>fb", "<cmd>Telescope buffers<cr>",                       desc = "Buffers" },
			{ "<leader>ff", "<cmd>Telescope find_files<cr>",                    desc = "Find Files (root dir)" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>",                      desc = "Recent" },
			-- git
			{ "<leader>gc", "<cmd>Telescope git_commits<CR>",                   desc = "commits" },
			{ "<leader>gs", "<cmd>Telescope git_status<CR>",                    desc = "status" },
			-- search
			{ "<leader>sa", "<cmd>Telescope autocommands<cr>",                  desc = "Auto Commands" },
			{ "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>",     desc = "Buffer" },
			{ "<leader>sc", "<cmd>Telescope command_history<cr>",               desc = "Command History" },
			{ "<leader>sC", "<cmd>Telescope commands<cr>",                      desc = "Commands" },
			{ "<leader>sd", "<cmd>Telescope diagnostics<cr>",                   desc = "Diagnostics" },
			{ "<leader>sh", "<cmd>Telescope help_tags<cr>",                     desc = "Help Pages" },
			{ "<leader>sH", "<cmd>Telescope highlights<cr>",                    desc = "Search Highlight Groups" },
			{ "<leader>sk", "<cmd>Telescope keymaps<cr>",                       desc = "Key Maps" },
			{ "<leader>sM", "<cmd>Telescope man_pages<cr>",                     desc = "Man Pages" },
			{ "<leader>sm", "<cmd>Telescope marks<cr>",                         desc = "Jump to Mark" },
			{ "<leader>so", "<cmd>Telescope vim_options<cr>",                   desc = "Options" },
			{ "<leader>sR", "<cmd>Telescope resume<cr>",                        desc = "Resume" },
		},
		config = function()
			require("telescope").load_extension("fzf")
		end,
	},

	{
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	},

	-- todo comments
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTelescope" },
		event = { "BufReadPost", "BufNewFile" },
		config = true,
		-- stylua: ignore
		keys = {
			{ "]t",         function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
			{ "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
			{ "<leader>st", "<cmd>TodoTelescope<cr>",                            desc = "Todo" },
		},
	},

	{ "tpope/vim-fugitive" },
}

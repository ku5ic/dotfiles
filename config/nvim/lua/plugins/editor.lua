return {
	-- file explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		keys = {
			{ "<C-enter>",   "<cmd>Neotree toggle<cr>", desc = "Toggle NeoTree" },
			{ "<C-S-enter>", "<cmd>NeoTreeReveal<cr>",  desc = "Reveal In NeoTree" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup()
		end,
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
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

				-- stylua: ignore start
				map("n", "]h", gs.next_hunk, "Next Hunk")
				map("n", "[h", gs.prev_hunk, "Prev Hunk")
				map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
				map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
				map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
				map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
				map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
				map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
				map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
				map("n", "<leader>ghd", gs.diffthis, "Diff This")
				map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
			end,
		},
	},

	-- fuzzy finder
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.1",
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

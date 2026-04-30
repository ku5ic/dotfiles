return {
	-- file explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
		lazy = false,
		opts = {
			close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
			popup_border_style = "rounded",
			window = {
				position = "left",
				width = 50,
			},
			symlink_target = {
				enabled = true,
			},
		},
	},

	-- search/replace in multiple files
	{
		"nvim-pack/nvim-spectre",
		build = false,
		cmd = "Spectre",
		keys = {
			{
				"<leader>sr",
				function()
					require("spectre").open()
				end,
				desc = "Search and replace",
			},
		},
		opts = { open_cmd = "noswapfile vnew" },
	},

	-- git signs
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = true,
	},

	-- fuzzy finder
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{
				"nvim-telescope/telescope-live-grep-args.nvim",
				-- This will not install any breaking changes.
				-- For major updates, this must be adjusted manually.
				version = "^1.0.0",
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
		},
		cmd = "Telescope",
		version = false, -- telescope did only one release, so use HEAD for now
		opts = {
			defaults = {
				mappings = {
					i = {
						["<c-d>"] = "delete_buffer",
					},
					n = {
						["<c-d>"] = "delete_buffer",
					},
				},
			},
		},
		config = function(PluginSpec)
			local telescope = require("telescope")
			telescope.setup(PluginSpec.opts)
			telescope.load_extension("fzf")
			telescope.load_extension("live_grep_args")
			telescope.load_extension("ui-select")
		end,
	},

	{
		"folke/which-key.nvim",
		dependencies = { "echasnovski/mini.icons" },
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			local wk = require("which-key")
			wk.setup()
			wk.add({
				{ "<leader>f", group = "find/file" },
				{ "<leader>s", group = "search" },
				{ "<leader>g", group = "git" },
				{ "<leader>w", group = "window" },
				{ "<leader>t", group = "tab/explorer" },
				{ "<leader>b", group = "buffer" },
				{ "<leader>l", group = "lsp" },
				{ "<leader>x", group = "diagnostics/trouble" },
				{ "<leader>d", group = "debug" },
				{ "<leader>a", group = "ai/copilot" },
				{ "<leader>n", group = "notifications/ui" },
				{ "<leader>c", group = "copy" },
			})
		end,
	},

	-- todo comments
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTelescope" },
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous todo comment",
			},
		},
		config = true,
	},

	-- vim-fugitive is a Git wrapper so awesome, it should be illegal
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-rhubarb" },

	-- lazygit.nvim is a plugin for managing git repositories
	{
		"kdheepak/lazygit.nvim",
		lazy = true,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},

	-- vim-tmux-navigator: jump between vim splits and tmux panes with C-hjkl + C-\
	-- Tmux side configured in ~/.tmux.conf.
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
			{ "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
			{ "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
			{ "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
			{ "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
		},
	},

	-- precognition.nvim assists with discovering motions (Both vertical and horizontal) to navigate your current buffer
	{
		"tris203/precognition.nvim",
		cmd = "Precognition",
		keys = {
			{ "<leader>np", "<cmd>Precognition toggle<cr>", desc = "Toggle Precognition" },
		},
		opts = {
			startVisible = false,
			-- showBlankVirtLine = true,
			-- highlightColor = { link = "Comment" },
			-- hints = {
			--      Caret = { text = "^", prio = 2 },
			--      Dollar = { text = "$", prio = 1 },
			--      MatchingPair = { text = "%", prio = 5 },
			--      Zero = { text = "0", prio = 1 },
			--      w = { text = "w", prio = 10 },
			--      b = { text = "b", prio = 9 },
			--      e = { text = "e", prio = 8 },
			--      W = { text = "W", prio = 7 },
			--      B = { text = "B", prio = 6 },
			--      E = { text = "E", prio = 5 },
			-- },
			-- gutterHints = {
			--     G = { text = "G", prio = 10 },
			--     gg = { text = "gg", prio = 9 },
			--     PrevParagraph = { text = "{", prio = 8 },
			--     NextParagraph = { text = "}", prio = 8 },
			-- },
		},
	},
}

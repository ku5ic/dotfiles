return {
	-- copilot
	{
		"github/copilot.vim",
		-- cmd = "Copilot",
		-- event = "InsertEnter",
		config = function()
			vim.g.copilot_filetypes = {
				["*"] = false,
				["css"] = true,
				["html"] = true,
				["javascript"] = true,
				["ruby"] = true,
				["python"] = true,
				["php"] = true,
				["lua"] = true,
				["typescript"] = true,
			}

			vim.g.copilot_node_command = "/Users/ku5ic/.nvm/versions/node/v16.19.1/bin/node"
			vim.g.copilot_no_tab_map = true
			vim.cmd[[highlight CopilotSuggestion guifg=#555555 ctermfg=8]]

			vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("")', { silent = true, expr = true })
		end,
	},
}

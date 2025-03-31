local M = {}

-- Define icons grouped by category for better readability and maintainability
M.icons = {
	diagnostics = {
		Error = " ",
		Warn = " ",
		Hint = " ",
		Info = " ",
	},
	git = {
		-- Change type
		added = "", -- nf-fa-plus_square
		modified = "", -- nf-oct-diff_modified
		deleted = "", -- nf-fa-minus_square
		removed = "", -- nf-oct-diff_removed (alternative to deleted)
		renamed = "󰁕", -- nf-md-file_replace
		copied = "", -- nf-fa-copy
		-- Status type
		untracked = "", -- nf-fa-question_circle
		ignored = "", -- nf-oct-file_submodule
		unstaged = "󰄱", -- nf-md-pencil_off
		staged = "", -- nf-fa-check_square
		conflict = "", -- nf-dev-git_merge
	},
	kinds = (function()
		-- Use a local table to avoid repetition and improve clarity
		local shared = {
			Function = " ",
			Key = " ",
			Module = " ",
			Namespace = " ",
		}
		return {
			Array = " ",
			Boolean = " ",
			Class = " ",
			Color = " ",
			Constant = " ",
			Constructor = shared.Function,
			Copilot = " ",
			Enum = " ",
			EnumMember = " ",
			Event = " ",
			Field = " ",
			File = " ",
			Folder = " ",
			Function = shared.Function,
			Interface = " ",
			Key = shared.Key,
			Keyword = " ",
			Method = shared.Function,
			Module = shared.Module,
			Namespace = shared.Namespace,
			Null = " ",
			Number = " ",
			Object = shared.Namespace,
			Operator = " ",
			Package = shared.Module,
			Property = " ",
			Reference = " ",
			Snippet = " ",
			String = " ",
			Struct = " ",
			Text = shared.Key,
			TypeParameter = " ",
			Unit = " ",
			Value = shared.Key,
			Variable = " ",
		}
	end)(),
}

return M

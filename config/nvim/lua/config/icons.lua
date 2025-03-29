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
		added = " ",
		modified = " ",
		removed = " ",
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

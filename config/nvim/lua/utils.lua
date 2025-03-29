local M = {}

-- utility function to set the description of a keymap
local set_desc = function(options, desc)
	return vim.tbl_extend("force", options, desc)
end

-- Utility function to merge multiple tables into one
local function merge_tables(...)
	local merged = {}
	for _, tbl in ipairs({ ... }) do
		for k, v in pairs(tbl) do
			merged[k] = v
		end
	end
	return merged
end

M.set_desc = set_desc
M.merge_tables = merge_tables

return M

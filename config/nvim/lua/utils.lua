local M = {}

local set_desc = function(options, desc)
	return vim.tbl_extend("force", options, desc)
end

M.set_desc = set_desc

return M

local M = {}

local set_desc = function(options, desc)
	return vim.tbl_extend("force", options, desc)
end

local function mergeTables(...)
	local mergedTable = {}
	for _, tbl in ipairs({ ... }) do
		for k, v in pairs(tbl) do
			mergedTable[k] = v
		end
	end
	return mergedTable
end

M.set_desc = set_desc
M.mergeTables = mergeTables

return M

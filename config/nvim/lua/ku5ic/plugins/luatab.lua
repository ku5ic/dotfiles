-- import luatab plugin safely
local setup, luatab = pcall(require, "luatab")
if not setup then
	return
end

-- enable luatab
luatab.setup()

local filetypes = require("config.filetypes")

local emmet_filetypes = vim.list_extend({ "html", "djangohtml", "svelte" }, filetypes.CSS)
vim.list_extend(emmet_filetypes, filetypes.JS_REACT)

return {
	filetypes = emmet_filetypes,
}

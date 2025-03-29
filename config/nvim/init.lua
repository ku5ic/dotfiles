local function ensure_lazy_nvim_installed()
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if vim.uv.fs_stat(lazypath) then
		return lazypath
	end

	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
	return lazypath
end

local lazypath = ensure_lazy_nvim_installed()
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("config.keymaps")
require("lazy").setup("plugins")

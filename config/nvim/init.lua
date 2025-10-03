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
	if not vim.uv.fs_stat(lazypath) then
		error("Failed to install lazy.nvim. Please check your git/network setup.")
	end
	return lazypath
end

local lazypath = ensure_lazy_nvim_installed()
vim.opt.rtp:prepend(lazypath)

-- Set leader key to space
vim.g.mapleader = " "

require("lazy").setup("plugins")
require("config.options")
require("keymaps.keymaps")
require("keymaps.copilotchat")

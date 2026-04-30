local o, g = vim.opt, vim.g

-- 1. External host executables
-- Resolve via PATH; fall back to asdf shim location for GUI launches that don't
-- inherit a shell PATH.
local function resolve_host(name, fallback)
	local path = vim.fn.exepath(name)
	if path == "" then
		path = vim.fn.expand(fallback)
	end
	return path ~= "" and path or nil
end

g.python3_host_prog = resolve_host("python3", "~/.asdf/shims/python")
g.ruby_host_prog = resolve_host("neovim-ruby-host", "~/.asdf/shims/neovim-ruby-host")

-- 2. Built-in plugins
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1 -- use oil.nvim / telescope-file-browser, etc.

-- 3. History / backups / undo
o.swapfile = false
o.backup = false
o.writebackup = false
o.undofile = true -- modern replacement
o.undodir = vim.fn.stdpath("state") .. "/undo"
o.history = 1000

-- 4. UI: line numbers, columns, colours
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.wrap = false
o.termguicolors = true
o.showtabline = 2
o.winbar = "%=%m %f" -- readonly + filename

-- 5. Indent / whitespace
o.expandtab = true
o.tabstop = 2
o.shiftwidth = 2
o.autoindent = true
o.list = true
o.listchars = {
	eol = "¬",
	tab = ">-",
	trail = "␣",
	extends = "»",
	precedes = "«",
	space = "·",
}

-- 6. Folding (Treesitter-driven)
-- Uses the native Neovim 0.10+ treesitter fold expression.
-- The legacy "nvim_treesitter#foldexpr()" Vimscript shim is deprecated.
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldenable = true
o.foldlevel = 99 -- keep everything open by default
o.foldlevelstart = 99
o.foldcolumn = "1"
o.fillchars = { -- table form parses faster in 0.11+
	eob = " ",
	fold = " ",
	foldopen = "",
	foldsep = " ",
	foldclose = "",
}

-- 7. Completion & search
o.completeopt = { "menu", "menuone", "noselect", "noinsert", "popup" }
o.ignorecase = true
o.smartcase = true

-- 8. Spelling
o.spell = true
o.spelllang = { "en_us" }
o.spellsuggest = { "best", 9 }
o.spelloptions = "camel"

-- 9. Clipboard / splits / misc
o.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
o.splitright = true
o.splitbelow = true
o.backspace = { "indent", "eol", "start" }
o.iskeyword:append("-")

vim.api.nvim_create_user_command("CopyPath", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

vim.api.nvim_create_user_command("CopyRelPath", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

-- Prefer :prepend when you *want* fzf earlier in rtp
local fzf_path = vim.fn.exepath("fzf")
if fzf_path ~= "" then
	o.runtimepath:prepend(vim.fn.fnamemodify(fzf_path, ":h"))
end

-- 10. Auto-reload files changed on disk
o.autoread = true
local autoreload = vim.api.nvim_create_augroup("dotfiles_autoreload", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	group = autoreload,
	command = "checktime",
})

-- 11. File types
vim.filetype.add({
	filename = {
		["Brewfile"] = "ruby",
	},
})

-- 12. Neovide
vim.o.guifont = "FiraCode Nerd Font Propo:h14"

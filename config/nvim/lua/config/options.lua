local opt = vim.opt -- for conciseness

vim.g.python3_host_prog = "~/.asdf/shims/python" -- use python3 from asdf
vim.g.ruby_host_prog = "~/.asdf/shims/ruby" -- use ruby from asdf

-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- backup and history
opt.swapfile = false
opt.backup = false
opt.wb = false
opt.history = 1000

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation & folding
opt.winbar = "%=%m %f" -- show file name and modified status in window bar
opt.expandtab = true -- expand tab to spaces
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.autoindent = true -- copy indent from current line when starting new one
opt.list = true -- show invisible characters
opt.foldenable = true -- enable folding
opt.foldcolumn = "1" -- show fold column
opt.foldmethod = "expr" -- use treesitter for folding
opt.foldexpr = "nvim_treesitter#foldexpr()" -- use treesitter for folding
opt.foldlevel = 99 -- open all folds by default
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]] -- fold characters

-- listchars
opt.listchars = { eol = "¬", tab = ">-", trail = "␣", extends = "»", precedes = "«", space = "·" }
-- opt.list = true

-- line wrapping
opt.wrap = false -- disable line wrapping

-- reload file changed outside vim
opt.autoread = true

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- spelling and encoding
opt.spell = true
opt.spelllang = { "en_us" }
opt.spellsuggest = { "best", 9 }
opt.encoding = "utf-8"
opt.spelloptions = "camel"

-- cursor line
opt.cursorline = true -- highlight the current cursor line

-- appearance
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift
opt.showtabline = 2

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically. Requires Neovim >= 0.10.0
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

opt.iskeyword:append("-") -- consider string-string as whole word
opt.runtimepath:append("/opt/homebrew/bin/fzf") -- add fzf to runtimepath

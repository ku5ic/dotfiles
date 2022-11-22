local opt = vim.opt -- for conciseness

-- backup and history
opt.swapfile = false
opt.backup = false
opt.wb = false
opt.history = 1000

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.expandtab = true -- expand tab to spaces
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.autoindent = true -- copy indent from current line when starting new one

-- listchars
opt.listchars = { eol = "¬", tab = ">·", trail = "~", extends = ">", precedes = "<", space = "␣" }
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
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

opt.iskeyword:append("-") -- consider string-string as whole word

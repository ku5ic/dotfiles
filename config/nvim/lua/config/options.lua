local opt = vim.opt -- for conciseness

-- Host programs for external integrations
vim.g.python3_host_prog = "~/.asdf/shims/python"
vim.g.ruby_host_prog = "~/.asdf/shims/neovim-ruby-host"

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Backup and history settings
opt.swapfile = false
opt.backup = false
opt.writebackup = false -- clearer alias for `wb`
opt.history = 1000

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs, indentation, and folding
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.autoindent = true
opt.list = true
opt.listchars = { eol = "¬", tab = ">-", trail = "␣", extends = "»", precedes = "«", space = "·" }
opt.winbar = "%=%m %f"
opt.foldenable = true
opt.foldcolumn = "1"
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevel = 99
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

-- Set completion options
opt.completeopt = "menu,menuone,noselect,noinsert,popup"

-- Line wrapping
opt.wrap = false

-- Auto-reload files changed outside Neovim
opt.autoread = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Spelling and encoding
opt.spell = true
opt.spelllang = { "en_us" }
opt.spellsuggest = { "best", 9 }
opt.spelloptions = "camel"
opt.encoding = "utf-8"

-- Cursor line
opt.cursorline = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.showtabline = 2

-- Backspace behavior
opt.backspace = { "indent", "eol", "start" }

-- Clipboard integration
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"

-- Split window behavior
opt.splitright = true
opt.splitbelow = true

-- Miscellaneous
opt.iskeyword:append("-")
opt.runtimepath:append("/opt/homebrew/bin/fzf")

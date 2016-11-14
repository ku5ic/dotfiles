" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" ================ General Config ====================

syntax on                       "turn on syntax highlighting
set noswapfile
set nobackup
set nowb
set number
set relativenumber              "Line numbers are good
set colorcolumn=80
set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000                "Store lots of :cmdline history
set showcmd                     "Show incomplete cmds down the bottom
set showmode                    "Show current mode down the bottom
set visualbell                  "No sounds
set autoread                    "Reload files changed outside vim
set cursorline                  " Highlight current line
set cursorcolumn                " Highlight current column
set cmdheight=2                 " Height of the command bar
set laststatus=2                " Always show the status line
set spell
set encoding=utf-8
set termencoding=utf-8
set mouse=a
set clipboard=unnamed
let shell="zsh\ -l"
set hidden
set autoindent
set smartindent
set smarttab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set list listchars=tab:\ \ ,trail:· " Display tabs and trailing spaces visually
set nowrap                      "Don't wrap lines
set linebreak                   "Wrap lines at convenient points
set foldmethod=indent           "fold based on indent
set foldnestmax=3               "deepest fold is 3 levels
set nofoldenable                "don't fold by default
set wildmode=list:longest
set wildmenu                    "enable ctrl-n and ctrl-p to scroll through matches
set wildignore=*DS_Store*
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=*.png,*.jpg,*.gif
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/*
set wildignore+=*/tmp/librarian/*,*/.vagrant/*,*/.kitchen/*,*/vendor/cookbooks/*
set wildignore+=*/tmp/cache/assets/*/sprockets/*,*/tmp/cache/assets/*/sass/*
set wildignore+=*/node_modules/*
set wildignore+=*.swp,*~,._*
set scrolloff=8                 "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=1
set ignorecase
set smartcase
set incsearch
set hlsearch
let mapleader=","

source ~/.vundle.vim
source ~/.keymappings.vim

" ================ Custom Settings ========================
set background=dark
colorscheme gruvbox

" ================ Custom File Types ========================
au BufRead,BufNewFile *.md set filetype=markdown
au BufRead,BufNewFile *.md.erb set filetype=eruby.markdown.html
"

let g:ruby_path = system('echo $HOME/.rbenv/shims')

if filereadable(glob("~/.vimrc.local"))
   source ~/.vimrc.local
endif

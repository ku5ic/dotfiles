set nocompatible

" syntax
syntax enable

" fix backspace
set bs=2

" backup and history
set noswapfile
set nobackup
set nowb
set history=1000

" numbers and rulers
set number
set numberwidth=2
set relativenumber
set colorcolumn=80
" set cursorline
set signcolumn=yes
" set cursorcolumn
set lazyredraw

" no sounds
set visualbell

" reload file changed outside vim
set autoread

" wildignore
set wildignore+=*/node_modules/**,*/bower_components/**,*/spec/reports/**,*/tmp/**
set wildignore+=*.png,*.PNG,*.jpg,*.jpeg,*.JPG,*.JPEG,*.pdf
set wildignore+=*.ttf,*.otf,*.woff,*.woff2,*.eot

" status line
set showcmd
set showmode
set cmdheight=1
set laststatus=2

" mouse and clipboard
set mouse=a
set clipboard=unnamed

" shell
let shell="/usr/local/bin/zsh\ -l"

set hidden

" indentation and tabs
set autoindent
set smartindent
set smarttab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set listchars=eol:¬,tab:»·,trail:·,nbsp:·,
set list
set nowrap
set linebreak
set scrolloff=8
set sidescrolloff=15
set sidescroll=1

" search
set ignorecase
set smartcase
set incsearch
set hlsearch
set shortmess+=c
let mapleader=","

source ~/.plugins.vim
source ~/.keymappings.vim

" term colors
if (has("termguicolors"))
  set termguicolors
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set term=xterm-256color
set termencoding=utf-8

" theme
set background=dark
colorscheme vim-material

" spelling and encoding
set nospell
syntax spell toplevel
set spelllang=en_us
set encoding=utf-8
" hi clear SpellBad
" hi clear SpellCap
" hi clear SpellRare
" hi clear SpellLocal
" hi SpellBad cterm=underline,bold
" hi SpellCap cterm=underline,bold
" hi SpellRare cterm=underline,bold
" hi SpellLocal cterm=underline,bold

" folding
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=2

" custom file types
au BufRead,BufNewFile {Capfile,Gemfile,Vagrantfile,Rakefile,Thorfile,config.ru,.caprc,.irbrc,irb_tempfile*} set ft=ruby
au BufRead,BufNewFile {*.jbuilder,*.rabl,*.rubyxl} setf ruby
au BufRead,BufNewFile *.go set filetype=go
au BufRead,BufNewFile *.snap set filetype=javasript.jsx

" ruby
let g:ruby_path=system('echo $HOME/.rbenv/shims')

if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif

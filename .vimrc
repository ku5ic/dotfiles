" This must be first, because it changes other options as a side effect.
set nocompatible

" syntax
syntax on

" backup and history
set noswapfile
set nobackup
set nowb
set history=1000

" numbers and rulers
set number
" set relativenumber
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

" spelling and encoding
set spell
set spl=en_us
set encoding=utf-8

" term colors
set termencoding=utf-8
set termguicolors

" mouse and clipboard
set mouse=a
set clipboard=unnamed

" shell
let shell="zsh\ -l"

set hidden

" indentation and tabs
set autoindent
set smartindent
set smarttab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set list listchars=tab:\ \ ,trail:·
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

source ~/.vundle.vim
source ~/.keymappings.vim

" theme
set background=dark
colorscheme gruvbox

" custom file types
au BufRead,BufNewFile *.md set filetype=markdown
au BufRead,BufNewFile *.md.erb set filetype=eruby.markdown.html
au BufRead,BufNewFile {Capfile,Gemfile,Vagrantfile,Rakefile,Thorfile,config.ru,.caprc,.irbrc,irb_tempfile*} set ft=ruby
au BufRead,BufNewFile {*.jbuilder,*.rabl,*.rubyxl} setf ruby
au BufNewFile,BufRead *.jst set syntax=jst
au BufRead,BufNewFile *.go set filetype=go

" ruby
let g:ruby_path=system('echo $HOME/.rbenv/shims')

if filereadable(glob("~/.vimrc.local"))
   source ~/.vimrc.local
endif

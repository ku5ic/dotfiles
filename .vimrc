set nocompatible

" term colors
if (has("termguicolors"))
  set termguicolors
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

if !has("gui_running")
  set term=xterm-256color
endif

set termencoding=utf-8

" disable arrow keys
" for key in ['<Up>', '<Down>', '<Left>', '<Right>']
"   exec 'noremap' key '<Nop>'
"   exec 'inoremap' key '<Nop>'
"   exec 'cnoremap' key '<Nop>'
" endfor

" syntax
syntax enable

" fix backspace
set backspace=indent,eol,start

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
set cursorline
set signcolumn=yes
set cursorcolumn
set lazyredraw

" no sounds
set noerrorbells visualbell t_vb=
set visualbell

" reload file changed outside vim
set autoread

" wildmenu
set wildmenu

" wildignore
set wildignore+=*/node_modules/**,*/bower_components/**,*/spec/reports/**,*/tmp/**,*/public/packs/**
set wildignore+=*.png,*.PNG,*.jpg,*.jpeg,*.JPG,*.JPEG,*.pdf
set wildignore+=*.ttf,*.otf,*.woff,*.woff2,*.eot
set wildignore+=*.pyc,*.o,*.obj,*.svn,*.swp,*.class,*.hg,*.DS_Store,*.min.*

" tabline
set showtabline=2

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

" splits
set splitright
set splitbelow

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
nnoremap <SPACE> <Nop>
let mapleader=" "

" update time
set updatetime=300

source ~/.plugins.vim
source ~/.keymappings.vim

" theme
set background=dark
colorscheme hybrid_material

" spelling and encoding
set nospell
syntax spell toplevel
set spelllang=en_us
set encoding=utf-8
hi clear SpellBad
hi clear SpellCap
hi clear SpellRare
hi clear SpellLocal
hi SpellBad cterm=underline,bold
hi SpellCap cterm=underline,bold
hi SpellRare cterm=underline,bold
hi SpellLocal cterm=underline,bold

" highlighting
hi Visual guibg=Orange guifg=LightYellow
hi CursorLine guibg=Gray10 guifg=NONE
hi Search guibg=Orange guifg=Gray10

" folding
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=2

" custom file types
au BufRead,BufNewFile {Capfile,Gemfile,Vagrantfile,Rakefile,Thorfile,config.ru,.caprc,.irbrc,irb_tempfile*} set ft=ruby
au BufRead,BufNewFile {*.jbuilder,*.rabl,*.rubyxl} set ft=ruby
au BufRead,BufNewFile *.go set ft=go
au BufRead,BufNewFile *.snap set ft=javascript.jsx
au BufRead,BufNewFile .babelrc set ft=javascript
au BufRead,BufNewFile {*.conf,*.cnf} setf dosini

" set spell for commit messages
au BufNewFile,BufRead COMMIT_EDITMSG setlocal spell

" ruby
let g:ruby_path=system('echo $HOME/.rbenv/shims')

" netrw
let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_browse_split=4
let g:netrw_altv=1
let g:netrw_winsize=25

if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif

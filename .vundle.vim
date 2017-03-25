" =============== Vundle Initialization ===============
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Bundle 'gmarik/Vundle.vim'

Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-rake'
Plugin 'tpope/vim-rbenv'
Plugin 'tpope/vim-eunuch'
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-haml'
Plugin 'ecomba/vim-ruby-refactoring'
Plugin 'scrooloose/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'idanarye/vim-merginal'
Plugin 'airblade/vim-gitgutter'
Plugin 'ddollar/nerdcommenter'
Plugin 'janko-m/vim-test'
Plugin 'vim-syntastic/syntastic'
Plugin 'othree/html5.vim'
Plugin 'hail2u/vim-css3-syntax'
Plugin 'gorodinskiy/vim-coloresque'
Plugin 'digitaltoad/vim-jade'
Plugin 'mustache/vim-mode'
Plugin 'kien/ctrlp.vim'
Plugin 'mattn/emmet-vim'
Plugin 'vim-airline/vim-airline'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'pangloss/vim-javascript'
Plugin 'kchmck/vim-coffee-script'
Plugin 'mtscout6/vim-cjsx'
Plugin 'mxw/vim-jsx'
Plugin 'craigemery/vim-autotag'
Plugin 'morhetz/gruvbox'
Plugin 'godlygeek/tabular'
Plugin 'valloric/youcompleteme'
Plugin 'jiangmiao/auto-pairs'

if filereadable(glob("~/.vundle.local"))
   source ~/.vundle.local
endif

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

let g:jsx_ext_required = 0

" Airline
let g:airline_powerline_fonts = 1
let g:airline_detect_modified = 1

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

if !exists('g:airline_powerline_fonts')
  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = '|'
  let g:airline_left_sep          = '▶'
  let g:airline_left_alt_sep      = '»'
  let g:airline_right_sep         = '◀'
  let g:airline_right_alt_sep     = '«'
  let g:airline#extensions#branch#prefix     = '⤴' "➔, ➥, ⎇
  let g:airline#extensions#readonly#symbol   = '⊘'
  let g:airline#extensions#linecolumn#prefix = '¶'
  let g:airline#extensions#paste#symbol      = 'ρ'
  let g:airline_symbols.linenr    = '␊'
  let g:airline_symbols.branch    = '⎇'
  let g:airline_symbols.paste     = 'ρ'
  let g:airline_symbols.paste     = 'Þ'
  let g:airline_symbols.paste     = '∥'
  let g:airline_symbols.whitespace = 'Ξ'
else
  let g:airline#extensions#tabline#left_sep = ''
  let g:airline#extensions#tabline#left_alt_sep = ''

  " powerline symbols
  let g:airline_left_sep = ''
  let g:airline_left_alt_sep = ''
  let g:airline_right_sep = ''
  let g:airline_right_alt_sep = ''
  let g:airline_symbols.branch = ''
  let g:airline_symbols.readonly = ''
  let g:airline_symbols.linenr = ''
endif

" NERDTree
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let NERDTreeAutoDeleteBuffer = 1

" Syntastic
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

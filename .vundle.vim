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
Plugin 'scrooloose/nerdtree'
Plugin 'xuyuanp/nerdtree-git-plugin'
Plugin 'ddollar/nerdcommenter'
Plugin 'janko-m/vim-test'
Plugin 'othree/html5.vim'
Plugin 'mustache/vim-mode'
Plugin 'StanAngeloff/php.vim'
Plugin 'kien/ctrlp.vim'
Plugin 'mattn/emmet-vim'
Plugin 'tomtom/tlib_vim'
Plugin 'bling/vim-airline'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'pangloss/vim-javascript'
Plugin 'kchmck/vim-coffee-script'
Plugin 'mtscout6/vim-cjsx'
Plugin 'mxw/vim-jsx'
Plugin 'craigemery/vim-autotag'
"Plugin 'godlygeek/csapprox' "Make gvim-only colorschemes work transparently in terminal vim
"Plugin 'altercation/vim-colors-solarized'
Plugin 'morhetz/gruvbox'
Plugin 'majutsushi/tagbar'

if filereadable(glob("~/.vundle.local"))
   source ~/.vundle.local
endif

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

let g:jsx_ext_required = 0
let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['\.DS_Store$']
let g:airline_powerline_fonts = 1
let g:airline_detect_modified = 1
nmap <F8> :TagbarToggle<CR>

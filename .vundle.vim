" =============== Vundle Initialization ===============
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Bundle 'gmarik/Vundle.vim'

Plugin 'scrooloose/nerdtree'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-rake'
Plugin 'tpope/vim-rbenv'
Plugin 'tpope/vim-eunuch'
Plugin 'janko-m/vim-test'
Plugin 'othree/html5.vim'
Plugin 'mustache/vim-mode'
Plugin 'kchmck/vim-coffee-script'
Plugin 'StanAngeloff/php.vim'
Plugin 'kien/ctrlp.vim'
Plugin 'ddollar/nerdcommenter'
Plugin 'mattn/emmet-vim'
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-surround'
Plugin 'tomtom/tlib_vim'
Plugin 'bling/vim-airline'
Plugin 'editorconfig/editorconfig-vim'
"Plugin 'godlygeek/csapprox' "Make gvim-only colorschemes work transparently in terminal vim
"Plugin 'altercation/vim-colors-solarized'
Plugin 'morhetz/gruvbox'

if filereadable(glob("~/.vundle.local"))
   source ~/.vundle.local
endif

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

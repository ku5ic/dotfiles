call plug#begin('~/.vim/plugged')

" basic
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rbenv'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'airblade/vim-gitgutter'
Plug 'vim-scripts/grep.vim'
Plug 'vim-scripts/CSApprox'
Plug 'bronson/vim-trailing-whitespace'
Plug 'Raimondi/delimitMate'
Plug 'majutsushi/tagbar'
Plug 'Yggdroot/indentLine'
Plug 'avelino/vim-bootstrap-updater'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-dotenv'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'w0rp/ale'
Plug 'mattn/emmet-vim'
Plug 'editorconfig/editorconfig-vim'
Plug 'ryanoasis/vim-devicons'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'janko-m/vim-test'
"
" themes
Plug 'morhetz/gruvbox'
" Plug 'kaicataldo/material.vim'
Plug 'kristijanhusak/vim-hybrid-material'
Plug 'hzchirs/vim-material'

"*****************************************************************************
"" Custom bundles
"*****************************************************************************

" c
Plug 'vim-scripts/c.vim', {'for': ['c', 'cpp']}
Plug 'ludwig/split-manpage.vim'

" elixir
Plug 'elixir-lang/vim-elixir'
Plug 'carlosgaldino/elixir-snippets'
Plug 'mxw/vim-jsx'

" elm
"" Elm Bundle
Plug 'elmcast/elm-vim'

" erlang
Plug 'jimenezrick/vimerl'

" go
"" Go Lang Bundle
Plug 'fatih/vim-go', {'do': ':GoInstallBinaries'}

" haskell
"" Haskell Bundle
Plug 'eagletmt/neco-ghc'
Plug 'dag/vim2hs'
Plug 'pbrisbin/vim-syntax-shakespeare'

" html
"" HTML Bundle
Plug 'hail2u/vim-css3-syntax'
Plug 'gorodinskiy/vim-coloresque'
Plug 'tpope/vim-haml'
Plug 'mattn/emmet-vim'

" javascript
"" Javascript Bundle
Plug 'jelera/vim-javascript-syntax'

" lisp
"" Lisp Bundle
Plug 'vim-scripts/slimv.vim'

" lua
"" Lua Bundle
" Plug 'xolox/vim-lua-ftplugin'
" Plug 'xolox/vim-lua-inspect'

" ocaml
"" OCaml Bundle
Plug 'def-lkb/ocp-indent-vim'

" perl
"" Perl Bundle
Plug 'vim-perl/vim-perl'
Plug 'c9s/perlomni.vim'

" php
"" PHP Bundle
Plug 'arnaud-lb/vim-php-namespace'

" python
"" Python Bundle
Plug 'davidhalter/jedi-vim'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'glench/vim-jinja2-syntax'

" ruby
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-projectionist'
Plug 'thoughtbot/vim-rspec'
Plug 'ecomba/vim-ruby-refactoring'

" rust
" Vim racer
Plug 'racer-rust/vim-racer'

" Rust.vim
Plug 'rust-lang/rust.vim'


" scala
if has('python')
    " sbt-vim
    Plug 'ktvoelker/sbt-vim'
endif
" vim-scala
Plug 'derekwyatt/vim-scala'

if filereadable(glob("~/.plugins.local"))
   source ~/.plugins.local
endif

call plug#end()
filetype plugin indent on

" Devicons
let g:webdevicons_enable_nerdtree=1
let g:webdevicons_enable_airline_tabline=1
let g:webdevicons_enable_airline_statusline=1
let g:WebDevIconsUnicodeGlyphDoubleWidth=1
let g:webdevicons_conceal_nerdtree_brackets=1
" let g:WebDevIconsNerdTreeAfterGlyphPadding=''
let g:WebDevIconsNerdTreeGitPlugForceVAlign=1
let g:WebDevIconsOS='Darwin'
let g:NERDTreeFileExtensionHighlightFullName=1
let g:WebDevIconsUnicodeDecorateFolderNodes=1
let g:DevIconsEnableFoldersOpenClose=1
if exists('g:loaded_webdevicons')
  call webdevicons#refresh()
endif

" Airline
let g:airline_powerline_fonts=1
if !exists('g:airline_symbols')
    let g:airline_symbols={}
endif
let g:airline#extensions#tabline#fnamemod=':t'
let g:airline_detect_modified=1
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#branch#prefix='⤴' "➔, ➥, ⎇
let g:airline#extensions#readonly#symbol='⊘'
let g:airline#extensions#linecolumn#prefix='¶'
let g:airline#extensions#paste#symbol='ρ'
let g:airline_symbols.linenr='␊'
let g:airline_symbols.branch='⎇'
let g:airline_symbols.paste='ρ'
let g:airline_symbols.paste='Þ'
let g:airline_symbols.paste='∥'
let g:airline_symbols.whitespace='Ξ'

" NERDTree
let NERDTreeWinSize=50
let NERDTreeShowHidden=1
let NERDTreeMinimalUI=1
let NERDTreeDirArrows=1
let NERDTreeAutoDeleteBuffer=1
let NERDTreeQuitOnOpen=1
let NERDTreeIgnore=['\.DS_Store', '\~$', '\.swp']
let g:NERDTreeDirArrowExpandable=""
let g:NERDTreeDirArrowCollapsible=""
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ 'Ignored'   : "☒",
    \ "Unknown"   : "?"
    \ }
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Ctrl-P
let g:ctrlp_custom_ignore = {
      \ 'dir':  '\.git$\|\.hg$\|\.svn$\|bower_components$\|dist$\|node_modules$\|project_files$\|test$',
      \ 'file': '\.exe$\|\.so$\|\.dll$\|\.pyc$' }

" Asynchronous Lint Engine
let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'ruby': ['rubocop'],
\}
let g:ale_fix_on_save=1
let g:ale_sign_column_always=1
let g:ale_sign_error='•'
let g:ale_sign_warning='•'
let g:airline#extensions#ale#enabled=1
let g:ale_echo_msg_error_str='E'
let g:ale_echo_msg_warning_str='W'
let g:ale_echo_msg_format='[%linter%] %s [%severity%]'
let g:ale_set_highlights=0
" let g:ale_lint_on_text_changed='never'

" JavaScript
let g:javascript_plugin_jsdoc=1
let g:javascript_plugin_ngdoc=1
let g:javascript_plugin_flow=1

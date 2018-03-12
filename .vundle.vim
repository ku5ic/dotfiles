filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Bundle 'gmarik/Vundle.vim'

" tpope
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-rake'
Plugin 'tpope/vim-rbenv'
Plugin 'tpope/vim-eunuch'
Plugin 'tpope/vim-sensible'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-vinegar'

" language packs
Plugin 'sheerun/vim-polyglot'
Plugin 'othree/javascript-libraries-syntax.vim'

" testing and refactoring
Plugin 'ecomba/vim-ruby-refactoring'
Plugin 'janko-m/vim-test'

" file browsing
" Plugin 'scrooloose/nerdtree'
" Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'ctrlpvim/ctrlp.vim'

" Git
Plugin 'airblade/vim-gitgutter'

" status lines
Plugin 'vim-airline/vim-airline'

" code completion
Plugin 'Valloric/YouCompleteMe'
Plugin 'mattn/emmet-vim'
Plugin 'ddollar/nerdcommenter'

" text filtering and alignment
Plugin 'godlygeek/tabular'

" themes
Plugin 'morhetz/gruvbox'

" linters
Plugin 'w0rp/ale'

" misc
Plugin 'editorconfig/editorconfig-vim'
Plugin 'ryanoasis/vim-devicons'

if filereadable(glob("~/.vundle.local"))
   source ~/.vundle.local
endif

" All of your Plugins must be added before the following line
call vundle#end()
filetype plugin indent on

" Devicons
let g:webdevicons_enable_nerdtree=1
let g:webdevicons_enable_airline_tabline=1
let g:webdevicons_enable_airline_statusline=1
let g:WebDevIconsUnicodeGlyphDoubleWidth=1
let g:webdevicons_conceal_nerdtree_brackets=1
let g:WebDevIconsNerdTreeAfterGlyphPadding=' '
let g:WebDevIconsNerdTreeGitPluginForceVAlign=0
let g:WebDevIconsOS='Darwin'
let g:NERDTreeFileExtensionHighlightFullName=1
let g:WebDevIconsUnicodeDecorateFolderNodes=1
" let g:DevIconsEnableFoldersOpenClose=1

" JSX
let g:jsx_ext_required=0

" JavaScript libraries syntax
let g:used_javascript_libs='underscore,backbone,react,jquery,d3,jasmine,chai,vue,jest'

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
" let NERDTreeWinSize=50
" let NERDTreeShowHidden=1
" let NERDTreeMinimalUI=1
" let NERDTreeDirArrows=1
" let NERDTreeAutoDeleteBuffer=1
" let NERDTreeQuitOnOpen=1
" let NERDTreeIgnore=['\.DS_Store', '\~$', '\.swp']
" let g:NERDTreeDirArrowExpandable=""
" let g:NERDTreeDirArrowCollapsible=""
" let g:NERDTreeIndicatorMapCustom = {
    " \ "Modified"  : "✹",
    " \ "Staged"    : "✚",
    " \ "Untracked" : "✭",
    " \ "Renamed"   : "➜",
    " \ "Unmerged"  : "═",
    " \ "Deleted"   : "✖",
    " \ "Dirty"     : "✗",
    " \ "Clean"     : "✔︎",
    " \ 'Ignored'   : "☒",
    " \ "Unknown"   : "?"
    " \ }
" autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" NERD Commenter
let g:NERDSpaceDelims=1
let g:NERDDefaultAlign='left'

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
" let g:ale_lint_on_text_changed='never'

" Gruvbox
let g:gruvbox_contrast_dark='hard'
let g:gruvbox_improved_strings=0
nnoremap <silent> [oh :call gruvbox#hls_show()<CR>
nnoremap <silent> ]oh :call gruvbox#hls_hide()<CR>
nnoremap <silent> coh :call gruvbox#hls_toggle()<CR>

nnoremap * :let @/ = ""<CR>:call gruvbox#hls_show()<CR>*
nnoremap / :let @/ = ""<CR>:call gruvbox#hls_show()<CR>/
nnoremap ? :let @/ = ""<CR>:call gruvbox#hls_show()<CR>?

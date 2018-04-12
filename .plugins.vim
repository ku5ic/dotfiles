call plug#begin('~/.vim/plugged')

" tpope
Plug 'tpope/vim-git'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-dotenv'
Plug 'tpope/vim-markdown'

" language packs
" Plug 'sheerun/vim-polyglot'
Plug 'othree/yajs.vim'
Plug 'othree/javascript-libraries-syntax.vim'
Plug 'mxw/vim-jsx'

" testing and refactoring
Plug 'ecomba/vim-ruby-refactoring'
Plug 'janko-m/vim-test'

" file browsing
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ctrlpvim/ctrlp.vim'

" Git
Plug 'airblade/vim-gitgutter'

" status lines
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" code completion
function! BuildYCM(info)
  " info is a dictionary with 3 fields
  " - name:   name of the plugin
  " - status: 'installed', 'updated', or 'unchanged'
  " - force:  set on PlugInstall! or PlugUpdate!
  if a:info.status == 'installed' || a:info.force
    !./install.py
    execute 'cd' fnameescape('~/.vim/plugged/YouCompleteMe/third_party/ycmd/third_party/tern_runtime')
    !npm install --production
  endif
endfunction

Plug 'Valloric/YouCompleteMe', { 'do': function('BuildYCM') }
Plug 'mattn/emmet-vim'

" text filtering and alignment
Plug 'godlygeek/tabular'

" themes
Plug 'morhetz/gruvbox'
Plug 'nanotech/jellybeans.vim'
Plug 'tomasr/molokai'
Plug 'sjl/badwolf'
Plug 'mhartington/oceanic-next'
Plug 'ayu-theme/ayu-vim'

" linters
Plug 'w0rp/ale'

" misc
Plug 'editorconfig/editorconfig-vim'
Plug 'ryanoasis/vim-devicons'

if filereadable(glob("~/.plugins.local"))
   source ~/.plugins.local
endif

call plug#end()

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

" Gruvbox
" let g:gruvbox_contrast_dark='hard'
" let g:gruvbox_improved_strings=0
" nnoremap <silent> [oh :call gruvbox#hls_show()<CR>
" nnoremap <silent> ]oh :call gruvbox#hls_hide()<CR>
" nnoremap <silent> coh :call gruvbox#hls_toggle()<CR>

" nnoremap * :let @/ = ""<CR>:call gruvbox#hls_show()<CR>*
" nnoremap / :let @/ = ""<CR>:call gruvbox#hls_show()<CR>/
" nnoremap ? :let @/ = ""<CR>:call gruvbox#hls_show()<CR>?

" YouCOmpleteMe
" Don't show YCM's preview window [ I find it really annoying ]
set completeopt-=preview
let g:ycm_add_preview_to_completeopt=0
let g:ycm_collect_identifiers_from_tags_files=1

" JavaScript
let g:javascript_plugin_jsdoc=1
let g:javascript_plugin_ngdoc=1
let g:javascript_plugin_flow=1

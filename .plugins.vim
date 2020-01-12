call plug#begin('~/.vim/plugged')

" basic
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-dotenv'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-surround'
Plug 'itchyny/lightline.vim'
Plug 'maximbaz/lightline-ale'
Plug 'airblade/vim-gitgutter'
Plug 'vim-scripts/grep.vim'
Plug 'bronson/vim-trailing-whitespace'
Plug 'Raimondi/delimitMate'
Plug 'Yggdroot/indentLine'
Plug 'sheerun/vim-polyglot'
Plug 'w0rp/ale'
Plug 'editorconfig/editorconfig-vim'
Plug 'ryanoasis/vim-devicons'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'janko-m/vim-test'
Plug 'thoughtbot/vim-rspec'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'mattn/emmet-vim'

" themes
Plug 'kaicataldo/material.vim'

if filereadable(glob("~/.plugins.local"))
   source ~/.plugins.local
endif

call plug#end()
filetype plugin indent on

" NERDTree
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

" Vim Devicons
let g:WebDevIconsOS='Darwin'
let g:WebDevIconsUnicodeGlyphDoubleWidth=1
let g:WebDevIconsNerdTreeAfterGlyphPadding=' '
let g:WebDevIconsNerdTreeGitPluginForceVAlign=0

" Lightline
let g:lightline = {
      \   'colorscheme': 'material_vim',
      \   'active': {
      \     'left':[ [ 'mode', 'paste' ],
      \              [ 'cocstatus', 'gitbranch', 'readonly', 'filename', 'modified' ]
      \     ]
      \   },
      \   'component': {
      \     'lineinfo': ' %3l:%-2v',
      \   },
      \   'component_function': {
      \     'gitbranch': 'fugitive#head',
      \     'cocstatus': 'coc#status',
      \   }
      \ }

let g:lightline.component_expand = {
      \  'linter_checking': 'lightline#ale#checking',
      \  'linter_warnings': 'lightline#ale#warnings',
      \  'linter_errors': 'lightline#ale#errors',
      \  'linter_ok': 'lightline#ale#ok',
      \ }

let g:lightline.component_type = {
      \     'linter_checking': 'left',
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \     'linter_ok': 'left',
      \ }

let g:lightline.active = { 'right': [[ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ]] }

" Matherial Theme
let g:material_theme_style='palenight'

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
let g:ale_echo_msg_error_str='•'
let g:ale_echo_msg_warning_str='•'
let g:ale_echo_msg_format='[%linter%] %s [%severity%]'
let g:ale_set_highlights=0
" let g:ale_lint_on_text_changed='never'
let g:ale_ruby_rubocop_executable = '/Users/ku5ic/.rbenv/shims/bundle'

" Coc
" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()

" use <c-space>for trigger completion
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

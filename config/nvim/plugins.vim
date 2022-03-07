call plug#begin()

" basic
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-surround'
Plug 'itchyny/lightline.vim'
Plug 'airblade/vim-gitgutter'
Plug 'bronson/vim-trailing-whitespace'
Plug 'sheerun/vim-polyglot'
Plug 'w0rp/ale'
Plug 'editorconfig/editorconfig-vim'
Plug 'janko-m/vim-test'
Plug 'thoughtbot/vim-rspec'
Plug 'mattn/emmet-vim'
Plug 'maximbaz/lightline-ale'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" themes
Plug 'kristijanhusak/vim-hybrid-material'

if filereadable(glob("~/.plugins.local"))
  source ~/.plugins.local
endif

call plug#end()
filetype plugin indent on

" Lightline
let g:lightline = {
      \   'colorscheme': 'material',
      \   'active': {
        \     'left':[ [ 'mode', 'paste' ],
        \              [ 'gitbranch', 'cocstatus', 'readonly', 'filename', 'modified' ]
        \     ],
        \    'right': [[ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok' ]]
        \   },
        \   'component': {
          \     'lineinfo': ' %3l:%-2v',
          \   },
          \   'component_function': {
            \     'gitbranch': 'fugitive#head',
            \     'cocstatus': 'coc#status',
            \     'linter_checking': 'lightline#ale#checking',
            \     'linter_infos': 'lightline#ale#infos',
            \     'linter_warnings': 'lightline#ale#warnings',
            \     'linter_errors': 'lightline#ale#errors',
            \     'linter_ok': 'lightline#ale#ok',
            \   }
            \ }

let g:lightline.component_type = {
      \     'linter_checking': 'right',
      \     'linter_infos': 'right',
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \     'linter_ok': 'right',
      \ }

" Asynchronous Lint Engine
let g:ale_sign_error = '•'
let g:ale_sign_warning = '•'
let g:ale_echo_msg_error_str='E'
let g:ale_echo_msg_warning_str='W'
let g:ale_fixers = {
      \   'javascript': ['eslint'],
      \   'ruby': ['rubocop'],
      \}
let g:ale_fix_on_save=1
let g:ale_sign_column_always=1
let g:ale_change_sign_column_color=1
let g:ale_echo_msg_format='[%linter%] %s [%severity%]'
let g:ale_set_highlights=1
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

" hybrid material
let g:enable_bold_font = 1

if !exists('$TMUX')
  let g:enable_italic_font = 1
endif

if (!has("gui_running"))
  let g:hybrid_transparent_background = 1
endif

" ruby
let g:ruby_path=system('echo $HOME/.rbenv/shims')

" netrw
let g:netrw_preview=1
let g:netrw_banner=0
let g:netrw_liststyle=3
" let g:netrw_altv=1
let g:netrw_winsize=25

" nvim-tree
lua require'nvim-tree'.setup {
      \  view={
      \width=50
      \}
      \}

let g:lua_tree_size=40
nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <C-f> :NvimTreeFindFileToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>

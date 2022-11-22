call plug#begin()

" Basic
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-rhubarb'
Plug 'airblade/vim-gitgutter'
Plug 'bronson/vim-trailing-whitespace'
Plug 'sheerun/vim-polyglot'
Plug 'editorconfig/editorconfig-vim'
Plug 'janko-m/vim-test'
Plug 'thoughtbot/vim-rspec'
Plug 'mattn/emmet-vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'itchyny/lightline.vim'
Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Themes
Plug 'kaicataldo/material.vim', { 'branch': 'main' }
Plug 'navarasu/onedark.nvim'
Plug 'morhetz/gruvbox'
Plug 'shinchu/lightline-gruvbox.vim'

" Improved syntax highlight
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'lewis6991/spellsitter.nvim'


call plug#end()
filetype plugin indent on

" Lightline
let g:lightline = {
      \   'colorscheme': 'gruvbox',
      \   'active': {
        \     'left':[ [ 'mode', 'paste' ], [ 'gitbranch', 'readonly', 'filename', 'modified' ] ],
        \    'right': [[ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok', 'lineinfo' ]]
        \   },
        \   'component': {
          \     'lineinfo': ' %3l:%-2v',
          \   },
          \   'component_function': {
            \     'gitbranch': 'FugitiveHead',
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
let g:ale_fix_on_save=0
let g:ale_sign_column_always=1
let g:ale_change_sign_column_color=0
let g:ale_echo_msg_format='[%linter%] %s [%severity%]'
let g:ale_set_highlights=1
let g:ale_ruby_rubocop_executable = 'bundle'
let g:ale_linters = {
\   'javascript': ['eslint'],
\   'ruby': ['rubocop'],
\}
let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'css': ['prettier'],
\}

" ruby
let g:ruby_path=system('echo $HOME/.rbenv/shims/ruby')

" netrw
let g:netrw_preview=1
let g:netrw_banner=0
let g:netrw_liststyle=0
" let g:netrw_altv=1
let g:netrw_winsize=25

" Material
let g:material_theme_style = 'darker'
let g:material_terminal_italics = 1

" OneDark
let g:onedark_config = {
    \ 'style': 'cool',
\}

" Gruvbox
let g:gruvbox_italic = 1

" Telescope
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_oags<cr>


lua <<EOF

require'spellsitter'.setup()
require'nvim-treesitter.configs'.setup{highlight={enable=true}}

EOF

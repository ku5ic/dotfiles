call plug#begin()

" basic
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

" themes
" Plug 'kristijanhusak/vim-hybrid-material'
Plug 'mhartington/oceanic-next'
" Plug 'kaicataldo/material.vim', { 'branch': 'main' }
" Plug 'sonph/onehalf', { 'rtp': 'vim' }
" Plug 'jacoborus/tender.vim'
" Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'luisiacc/gruvbox-baby', {'branch': 'main'}

call plug#end()
filetype plugin indent on

" Lightline
let g:lightline = {
      \   'colorscheme': 'solarized',
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
let g:ale_change_sign_column_color=1
let g:ale_echo_msg_format='[%linter%] %s [%severity%]'
let g:ale_set_highlights=0
let g:ale_ruby_rubocop_executable = 'bundle'
let g:ale_linters = {
\   'javascript': ['eslint'],
\   'ruby': ['rubocop'],
\}

" ruby
let g:ruby_path=system('echo $HOME/.adsf/shims/ruby')

" netrw
let g:netrw_preview=1
let g:netrw_banner=0
let g:netrw_liststyle=0
" let g:netrw_altv=1
let g:netrw_winsize=25

" hybrid material
" let g:enable_bold_font = 1

" if !exists('$TMUX')
"   let g:enable_italic_font = 1
" endif

" if (!has("gui_running"))
"   let g:hybrid_transparent_background = 1
" endif

" OceanicNext
" let g:oceanic_next_terminal_bold = 1
" let g:oceanic_next_terminal_italic = 1

" Gruvbox Baby
let g:gruvbox_baby_function_style = "NONE"
let g:gruvbox_baby_keyword_style = "italic"
let g:gruvbox_baby_telescope_theme = 1
if !has("gui_running")
  let g:gruvbox_baby_transparent_mode = 1
endif

" Telescope
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_oags<cr>

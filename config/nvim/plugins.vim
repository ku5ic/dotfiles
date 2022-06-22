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
Plug 'kristijanhusak/vim-hybrid-material'
Plug 'kaicataldo/material.vim', { 'branch': 'main' }
Plug 'itchyny/lightline.vim'
Plug 'dense-analysis/ale'
Plug 'neovim/nvim-lspconfig'

call plug#end()
filetype plugin indent on

" Lightline
let g:lightline = {
      \   'colorscheme': 'one',
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
let g:ruby_path=system('echo $HOME/.rbenv/shims')

" netrw
let g:netrw_preview=1
let g:netrw_banner=0
let g:netrw_liststyle=0
" let g:netrw_altv=1
let g:netrw_winsize=25

" hybrid material
let g:enable_bold_font = 1

if !exists('$TMUX')
  let g:enable_italic_font = 1
endif

if (!has("gui_running"))
  let g:hybrid_transparent_background = 1
endif

" Telescope
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" lspconfig
lua << EOF

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', vim.lsp.buf.formatting, bufopts)
end

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

local nvim_lsp = require('lspconfig')

nvim_lsp.cssls.setup{
  on_attach = on_attach,
  flags = lsp_flags,
}

nvim_lsp.solargraph.setup{
  on_attach = on_attach,
  flags = lsp_flags,
}

nvim_lsp.tsserver.setup{
  on_attach = on_attach,
  flags = lsp_flags,
}

nvim_lsp.pyright.setup{
  on_attach = on_attach,
  flags = lsp_flags,
}

EOF

" Strip trailing white space (,ss)
function! StripWhitespace()
  let save_cursor = getpos(".")
  let old_query = getreg('/')
  :%s/\s\+$//e
  call setpos('.', save_cursor)
  call setreg('/', old_query)
endfunction

noremap <leader>ss :call StripWhitespace()<CR>

" Save a file as root (,W)
noremap <leader>w :w<CR>
noremap <leader>W :w !sudo tee % > /dev/null<CR>

" only
noremap <leader>O :only<CR>

" CtrlP
map <C-b> :CtrlPBuffer<CR>

" Vim Test
nmap <silent> <leader>t :TestNearest<CR>
nmap <silent> <leader>T :TestFile<CR>
nmap <silent> <leader>a :TestSuite<CR>
nmap <silent> <leader>l :TestLast<CR>
nmap <silent> <leader>g :TestVisit<CR>

" Ruby refactoring
nnoremap <leader>rap  :RAddParameter<cr>
nnoremap <leader>rcpc :RConvertPostConditional<cr>
nnoremap <leader>rel  :RExtractLet<cr>
vnoremap <leader>rec  :RExtractConstant<cr>
vnoremap <leader>relv :RExtractLocalVariable<cr>
nnoremap <leader>rit  :RInlineTemp<cr>
vnoremap <leader>rrlv :RRenameLocalVariable<cr>
vnoremap <leader>rriv :RRenameInstanceVariable<cr>
vnoremap <leader>rem  :RExtractMethod<cr>

" The NERD Tree
map <C-n> :NERDTreeToggle<CR>
map <C-f> :NERDTreeFind<CR>
map <C-g> :MerginalToggle<CR>

" Netrw
" Toggle Vexplore with Ctrl-E
" let g:NetrwIsOpen=0
" function! ToggleExplorer()
"   if g:NetrwIsOpen
"     let i = bufnr("$")
"     while (i >= 1)
"       if (getbufvar(i, "&filetype") == "netrw")
"         silent exe "bwipeout " . i
"       endif
"       let i-=1
"     endwhile
"     let g:NetrwIsOpen=0
"   else
"     let g:NetrwIsOpen=1
"     silent Lexplore
"   endif
" endfunction
" map <silent> <C-E> :call ToggleExplorer()<CR>
"

" Toggle spell checking on and off with (,s)
nmap <silent> <leader>s :set spell!<CR>

" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

if filereadable(glob("~/.keymappings.local"))
  source ~/.keymappings.local
endif

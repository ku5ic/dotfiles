set guifont=Sauce\ Code\ Powerline:h15

set guioptions-=r
set guioptions-=L

if filereadable(glob("~/.gvimrc.local"))
   source ~/.gvimrc.local
endif

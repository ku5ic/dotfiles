set guifont=Knack\ Nerd\ Font:h14

set guioptions-=r
set guioptions-=L

set linespace=0

if filereadable(glob("~/.gvimrc.local"))
   source ~/.gvimrc.local
endif

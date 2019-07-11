set guifont=Meslo\ LG\ M\ Regular\ Nerd\ Font\ Complete:h14
set guioptions-=r
set guioptions-=L
set guicursor+=a:blinkon0

if filereadable(glob("~/.gvimrc.local"))
  source ~/.gvimrc.local
endif


set guifont=Hack\ Regular\ Nerd\ Font\ Complete\ Mono:h14
set guioptions-=r
set guioptions-=L
set guicursor+=a:blinkon0

if filereadable(glob("~/.gvimrc.local"))
  source ~/.gvimrc.local
endif


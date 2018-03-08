set guifont=Meslo\ LG\ L\ Regular\ for\ Powerline\ Nerd\ Font\ Complete\ Mono:h12
set guioptions-=r
set guioptions-=L
set guicursor+=a:blinkon0
set linespace=0

if filereadable(glob("~/.gvimrc.local"))
  source ~/.gvimrc.local
endif

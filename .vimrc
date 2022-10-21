set nocompatible
colorscheme peachpuff
syntax on

let g:netrw_banner = 0
let g:netrw_liststyle = 3

set mouse=a
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set ai
set number
set hlsearch
set ruler
set linebreak
set nowrap
set incsearch
set scrolloff=8
set encoding=utf-8
set clipboard^=unnamed,unnamedplus
set backspace=indent,eol,start
set relativenumber

set backup
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set backupskip=/tmp/*,/private/tmp/*
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set writebackup

highlight Comment ctermfg=green

nnoremap <silent> t :Ex<CR>

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

" no more swaps, embrace the undodir
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile

highlight Comment ctermfg=green

nnoremap <silent> t :Ex<CR>

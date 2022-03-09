colorscheme peachpuff
filetype on
filetype plugin on
syntax on
set mouse=a
set shiftwidth=2
set tabstop=2
set softtabstop=2
set expandtab
set ai
set number
set hlsearch
set ruler
set linebreak
set scrolloff=5
set encoding=utf-8
set clipboard^=unnamed,unnamedplus
set backspace=indent,eol,start
set backupdir=/$TMPDIR//
set directory=/$TMPDIR//
set undodir=/$TMPDIR//
highlight Comment ctermfg=green

autocmd BufNewFile,BufReadPost *.pug set filetype=pug

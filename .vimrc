filetype plugin indent on
syntax on
colorscheme peachpuff
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
set scrolloff=10
set encoding=utf-8
set clipboard^=unnamed,unnamedplus
set backspace=indent,eol,start
set backupdir=/$TMPDIR//
set directory=/$TMPDIR//
set undodir=/$TMPDIR//
highlight Comment ctermfg=green

autocmd BufNewFile,BufReadPost *.pug set filetype=pug

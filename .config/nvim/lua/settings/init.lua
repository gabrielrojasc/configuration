local set = vim.opt
local g = vim.g

vim.cmd("colorscheme peachpuff")
vim.cmd("highlight Comment ctermfg=green")
vim.cmd("autocmd BufNewFile,BufRead *.rkt :set filetype=racket")
vim.cmd("hi rainbowcol1 guifg='#458588'")

g.netrw_banner = 0
g.netrw_liststyle = 3

set.compatible = false
set.expandtab = true
set.number = true
set.linebreak = true
set.shiftwidth = 2
set.tabstop = 2
set.softtabstop = 2
set.mouse = "a"
set.scrolloff = 8
set.encoding = "utf-8"
set.clipboard = "unnamed,unnamedplus"
set.guicursor = ""
set.relativenumber = true

-- no more swaps, embrace the undodir
set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.local/share/nvim/undodir"
set.undofile = true

local set = vim.opt
local g = vim.g

vim.cmd("colorscheme peachpuff")
vim.cmd("highlight Comment ctermfg=green")
vim.cmd("autocmd BufNewFile,BufRead *.rkt :set filetype=racket")
vim.cmd("hi rainbowcol1 guifg='#458588'")

g.netrw_banner = 0
g.netrw_liststyle = 3

set.number = true
set.relativenumber = true

set.scrolloff = 8

set.shiftwidth = 2
set.tabstop = 2
set.softtabstop = 2
set.expandtab = true
set.linebreak = true

set.signcolumn = "yes"

set.guicursor = ""

set.mouse = "a"

set.encoding = "utf-8"

set.clipboard = "unnamed,unnamedplus"

-- no more swaps, embrace the undodir
set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.local/share/nvim/undodir"
set.undofile = true

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
set.updatetime = 50

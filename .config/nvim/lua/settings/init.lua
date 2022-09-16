local set = vim.opt
local g = vim.g

vim.cmd("colorscheme peachpuff")
vim.cmd("highlight Comment ctermfg=green")
vim.cmd("nnoremap Y Y")

g.netrw_banner = 0
g.netrw_liststyle = 3
g.netrw_localrmdir = "rm -r"

set.compatible = false
set.expandtab = true
set.number = true
set.linebreak = true
set.shiftwidth = 2
set.tabstop = 2
set.softtabstop = 2
set.mouse = "a"
set.scrolloff = 8
set.laststatus = 1
set.encoding = "utf-8"
set.clipboard = "unnamed,unnamedplus"
set.backupdir = os.getenv("TMPDIR")
set.directory = os.getenv("TMPDIR")
set.undodir = os.getenv("TMPDIR")
set.guicursor = ""

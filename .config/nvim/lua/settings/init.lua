local set = vim.opt
local g = vim.g

vim.cmd.colorscheme("peachpuff")
vim.cmd("highlight Comment ctermfg=green")
vim.cmd("hi rainbowcol1 guifg='#458588'")

g.netrw_banner = 0
g.netrw_liststyle = 3

g.gitblame_highlight_group = "DiagnosticHint"
g.gitblame_date_format = "%r"
g.gitblame_delay = 300

g.editorconfig = true

set.number = true
set.relativenumber = true

set.scrolloff = 8

set.shiftwidth = 4
set.tabstop = 4
set.softtabstop = 4
set.expandtab = true
set.linebreak = true

set.signcolumn = "yes"

set.guicursor = ""

set.mouse = "a"

set.encoding = "utf-8"

set.clipboard = "unnamed,unnamedplus"

set.splitright = true

-- no more swaps, embrace the undodir
set.swapfile = false
set.backup = false
set.undodir = os.getenv("HOME") .. "/.local/share/nvim/undodir"
set.undofile = true

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
set.updatetime = 50

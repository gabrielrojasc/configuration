local map = vim.keymap.set
local opts = { silent = true }

map("n", "t", "<cmd>Ex<CR>", opts)
map("n", "ff", "<cmd>Telescope find_files hidden=true<CR>", opts)
map("n", "fg", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "N", "Nzzzv", opts)
map("n", "n", "nzzzv", opts)
map("n", "gv", "<C-w>v<C-]>", opts)
map("n", "j", "gj", opts)
map("n", "k", "gk", opts)

map("x", "p", '"_dP', opts)

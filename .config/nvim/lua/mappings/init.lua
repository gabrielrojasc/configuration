local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "t", ":Ex<CR>", opts)
map("n", "ff", ":Telescope find_files hidden=true<CR>", opts)
map("n", "fg", ":Telescope live_grep<CR>", opts)
map("x", "p", '"_dP', opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "N", "Nzzzv", opts)
map("n", "n", "nzzzv", opts)
map("n", "gv", "<C-w>v<C-]>", opts)

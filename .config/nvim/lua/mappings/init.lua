local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "t", ":Ex<CR>", opts)
map("n", "ff", ":Telescope find_files hidden=true<CR>", opts)
map("n", "fg", ":Telescope live_grep<CR>", opts)

local map = vim.api.nvim_set_keymap
local opts = { noremap =true, silent = true }

map("n", "t", ":NvimTreeToggle<CR>", opts)
map("n", "ff", ":Telescope find_files<CR>", opts)
map("n", "fg", ":Telescope live_grep<CR>", opts)

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
  vim.keymap.set("n", "<space>f", vim.lsp.buf.formatting, bufopts)
end

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

require("nvim-lsp-installer").setup({
  automatic_installation = true,
})

local lspconfig = require("lspconfig")

lspconfig["sumneko_lua"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["clangd"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["bashls"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["dockerls"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["emmet_ls"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["eslint"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["marksman"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["pyright"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})
lspconfig["html"].setup({
  on_attach = on_attach,
  flags = lsp_flags,
})

local sources = {
	require("null-ls").builtins.formatting.stylua,
	require("null-ls").builtins.formatting.shfmt,
	require("null-ls").builtins.formatting.eslint,
	require("null-ls").builtins.formatting.rustfmt,
	require("null-ls").builtins.formatting.black.with({ extra_args = { "--fast" } }),
	require("null-ls").builtins.formatting.isort,
}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

require("null-ls").setup({
	sources = sources,
	-- you can reuse a shared lspconfig on_attach callback here
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr })
				end,
			})
		end
	end,
})

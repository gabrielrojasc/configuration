local sources = {
	require("null-ls").builtins.formatting.stylua,
	require("null-ls").builtins.formatting.shfmt,
	require("null-ls").builtins.formatting.eslint,
	require("null-ls").builtins.formatting.rustfmt,
	require("null-ls").builtins.formatting.black,
	require("null-ls").builtins.formatting.isort,
	require("null-ls").builtins.diagnostics.flake8,
	-- require("null-ls").builtins.diagnostics.mypy,
}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local on_attach = function(client, bufnr)
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 2000 })
			end,
		})
	end
end

require("null-ls").setup({
	sources = sources,
	on_attach = on_attach,
})

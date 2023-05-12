local null_ls = require("null-ls")

local sources = {
	null_ls.builtins.formatting.stylua,
	null_ls.builtins.formatting.shfmt,
	null_ls.builtins.formatting.eslint,
	null_ls.builtins.formatting.stylelint,
	null_ls.builtins.formatting.rustfmt,
	null_ls.builtins.formatting.black,
	null_ls.builtins.formatting.ruff,
	null_ls.builtins.diagnostics.mypy,
	null_ls.builtins.diagnostics.ruff,
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

null_ls.setup({
	sources = sources,
	on_attach = on_attach,
})

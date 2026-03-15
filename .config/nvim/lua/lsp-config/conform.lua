local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		zsh = { "shfmt" },
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		html = { "prettier" },
		css = { "stylelint", "prettier" },
		scss = { "stylelint", "prettier" },
		less = { "stylelint", "prettier" },
	},
})

local augroup = vim.api.nvim_create_augroup("ConformFormatting", {})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	callback = function(args)
		conform.format({
			bufnr = args.buf,
			timeout_ms = 2000,
			lsp_fallback = true,
		})
	end,
})

-- setup needs to be mason -> mason-lspconfig -> lspconfig
require("mason").setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"pyright",
		"ruff_lsp",
		"html",
		"eslint",
		"stylelint_lsp",
		"marksman",
		"ansiblels",
		"bashls",
		"dockerls",
		"docker_compose_language_service",
	},
	automatic_installation = true,
})

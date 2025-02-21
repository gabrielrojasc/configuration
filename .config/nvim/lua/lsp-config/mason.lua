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
		"ansiblels",
		"bashls",
		"docker_compose_language_service",
		"dockerls",
		"eslint",
		"html",
		"lua_ls",
		"marksman",
		"pyright",
		"ruff",
		"stylelint_lsp",
		"tinymist",
		"yamlls",
	},
	automatic_installation = true,
})

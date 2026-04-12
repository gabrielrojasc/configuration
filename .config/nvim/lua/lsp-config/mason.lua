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
		"clangd",
		"docker_compose_language_service",
		"dockerls",
		"eslint",
		"gopls",
		"html",
		"jsonls",
		"lua_ls",
		"marksman",
		"pyright",
		"ruff",
		"rust_analyzer",
		"sqlls",
		"stylelint_lsp",
		"taplo",
		"tinymist",
		"ts_ls",
		"yamlls",
	},
	automatic_enable = false,
})

require("mason-tool-installer").setup({
	ensure_installed = {
		"shellcheck",
	},
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	-- formatting and linting
	"stevearc/conform.nvim",
	"mfussenegger/nvim-lint",
	-- mason
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
	},
	"williamboman/mason-lspconfig.nvim",
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	-- lsp config
	"neovim/nvim-lspconfig",
	-- cmp
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"hrsh7th/nvim-cmp",
	-- lua snip
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
	-- tree sitter
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
	},
	-- ts rainbow v2 (compatible with newer treesitter)
	"HiPhish/rainbow-delimiters.nvim",
	-- ts context
	"nvim-treesitter/nvim-treesitter-context",
	-- telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
	-- lualine
	"nvim-lualine/lualine.nvim",
	-- git blame
	"f-person/git-blame.nvim",
	-- comments
	{
		"numToStr/Comment.nvim",
		config = true,
	},
}

local opts = {
	ui = {
		icons = {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
}

require("lazy").setup(plugins, opts)

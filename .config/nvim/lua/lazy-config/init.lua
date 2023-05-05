local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
	-- null-ls
	"jose-elias-alvarez/null-ls.nvim",
	-- lsp config
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- mason
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	},
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
		build = ":TSUpdate",
	},
	-- ts rainbow
	"p00f/nvim-ts-rainbow",
	-- ts context
	"nvim-treesitter/nvim-treesitter-context",
	-- telescope
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	-- lualine
	{
		"nvim-lualine/lualine.nvim",
	},
	-- editorconfig
	"gpanders/editorconfig.nvim",
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

return require("packer").startup(function()
	-- package manager
	use("wbthomason/packer.nvim")
	use("jose-elias-alvarez/null-ls.nvim")

	-- lsp config
	use({
		"neovim/nvim-lspconfig",
		-- mason.nvim
		wants = {
			"mason.nvim",
			"mason-lspconfig.nvim",
		},
		requires = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	})

	-- cmp
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/nvim-cmp")

	-- lua snip
	use("L3MON4D3/LuaSnip")
	use("saadparwaiz1/cmp_luasnip")

	-- tree sitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})
	-- ts rainbow
	use("p00f/nvim-ts-rainbow")
	-- ts context
	use("nvim-treesitter/nvim-treesitter-context")

	-- telescope
	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.0",
		-- or, branch = "0.1.x",
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	-- lualine
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
	})
end)

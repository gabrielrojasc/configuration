return require("packer").startup(function()
	-- package manager
	use("wbthomason/packer.nvim")
	use("jose-elias-alvarez/null-ls.nvim")

	-- ThePrimeagen
	use("neovim/nvim-lspconfig")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/nvim-cmp")
	use("tzachar/cmp-tabnine", { run = "./install.sh" })
	use("onsails/lspkind-nvim")
	use("nvim-lua/lsp_extensions.nvim")
	use("glepnir/lspsaga.nvim")
	use("simrat39/symbols-outline.nvim")
	use("L3MON4D3/LuaSnip")
	use("saadparwaiz1/cmp_luasnip")
	-- nvim lsp installer
	use("williamboman/nvim-lsp-installer")
	-- tree sitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})
	-- ts rainbow
	use("p00f/nvim-ts-rainbow")
	-- telescope
	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.0",
		-- or                            , branch = "0.1.x",
		requires = { { "nvim-lua/plenary.nvim" } },
	})
end)

return require("packer").startup(function()
  -- package manager
  use("wbthomason/packer.nvim")
  use("jose-elias-alvarez/null-ls.nvim")

  -- lsp config
  use("neovim/nvim-lspconfig")
  -- nvim lsp installer
  use("williamboman/nvim-lsp-installer")

  -- cmp
  use('hrsh7th/cmp-nvim-lsp')
  use('hrsh7th/cmp-buffer')
  use('hrsh7th/cmp-path')
  use('hrsh7th/cmp-cmdline')
  use('hrsh7th/nvim-cmp')

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

  -- telescope
  use({
    "nvim-telescope/telescope.nvim",
    tag = "0.1.0",
    -- or, branch = "0.1.x",
    requires = { { "nvim-lua/plenary.nvim" } },
  })
end)

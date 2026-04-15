local treesitter = require("nvim-treesitter")

local languages = {
	"lua",
	"python",
	"javascript",
	"typescript",
	"html",
	"css",
	"json",
	"yaml",
	"toml",
	"bash",
	"vim",
	"vimdoc",
	"markdown",
	"markdown_inline",
	"go",
	"rust",
	"java",
	"c",
	"cpp",
	"dockerfile",
	"sql",
}

treesitter.setup()

treesitter.install(languages)

vim.api.nvim_create_autocmd("FileType", {
	pattern = languages,
	callback = function()
		vim.treesitter.start()
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

-- Configure treesitter-context (sticky headers)
require("treesitter-context").setup({
	enable = true, -- Enable the plugin
	max_lines = 4, -- How many lines the window should span
	min_window_height = 0, -- Minimum editor window height to enable context
	line_numbers = true, -- Display line numbers
	multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
	trim_scope = "outer", -- Which context lines to discard if max_lines is exceeded
	mode = "cursor", -- Line used to calculate context
	separator = nil, -- Separator between context and content
	zindex = 20, -- The Z-index of the context window
	on_attach = nil, -- Function to run when attaching to buffer
})

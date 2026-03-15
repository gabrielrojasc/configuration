local parser_install_dir = vim.fn.stdpath("data") .. "/site/parser"
vim.fn.mkdir(parser_install_dir, "p")

vim.opt.runtimepath:append(parser_install_dir)

require("nvim-treesitter.configs").setup({
	-- A list of parser names for commonly used languages
	ensure_installed = {
		"lua", "python", "javascript", "typescript", "html", "css", "json",
		"yaml", "toml", "bash", "vim", "vimdoc", "markdown", "markdown_inline",
		"go", "rust", "java", "c", "cpp", "dockerfile", "sql"
	},
	parser_install_dir = parser_install_dir,

	-- Install parsers synchronously (only applied to `ensure_installed`)
	sync_install = false,

	-- Automatically install missing parsers when entering buffer
	auto_install = true,

	indent = { enable = true, disable = { "python" } },

	highlight = {
		-- `false` will disable the whole extension
		enable = true,
		-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		-- Using this option may slow down your editor, and you may see some duplicate highlights.
		-- Instead of true it can also be a list of languages
		additional_vim_regex_highlighting = false,
	},
})

-- Configure treesitter-context (sticky headers)
require('treesitter-context').setup({
    enable = true,            -- Enable the plugin
    max_lines = 4,           -- How many lines the window should span
    min_window_height = 0,   -- Minimum editor window height to enable context
    line_numbers = true,     -- Display line numbers
    multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
    trim_scope = 'outer',    -- Which context lines to discard if max_lines is exceeded
    mode = 'cursor',         -- Line used to calculate context
    separator = nil,         -- Separator between context and content
    zindex = 20,            -- The Z-index of the context window
    on_attach = nil,        -- Function to run when attaching to buffer
})

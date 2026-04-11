local treesitter_filetypes = {
	"c",
	"cpp",
	"css",
	"dockerfile",
	"go",
	"html",
	"java",
	"javascript",
	"json",
	"lua",
	"markdown",
	"python",
	"rust",
	"sh",
	"sql",
	"toml",
	"typescript",
	"vim",
	"yaml",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = treesitter_filetypes,
	callback = function(args)
		local ok = pcall(vim.treesitter.start, args.buf)
		if not ok then
			return
		end

		vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

-- Configure treesitter-context (sticky headers)
require("treesitter-context").setup({
	enable = true,
	max_lines = 4,
	min_window_height = 0,
	line_numbers = true,
	multiline_threshold = 20,
	trim_scope = "outer",
	mode = "cursor",
	separator = nil,
	zindex = 20,
	on_attach = nil,
})

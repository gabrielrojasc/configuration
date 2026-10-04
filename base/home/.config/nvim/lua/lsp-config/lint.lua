local lint = require("lint")

local function pick(...)
	for _, name in ipairs({ ... }) do
		if lint.linters[name] then
			return name
		end
	end
	return nil
end

local function list(...)
	local out = {}
	for _, name in ipairs({ ... }) do
		if name then
			table.insert(out, name)
		end
	end
	return out
end

lint.linters_by_ft = {
	sh = list(pick("shellcheck")),
	bash = list(pick("shellcheck")),
	zsh = list(pick("shellcheck")),
}

local augroup = vim.api.nvim_create_augroup("NvimLint", {})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = augroup,
	callback = function()
		lint.try_lint()
	end,
})

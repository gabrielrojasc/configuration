-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }

-- Ensure mason-lspconfig is available
local mason_lspconfig = require("mason-lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities(vim.lsp.protocol.make_client_capabilities())

vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, opts)
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
	-- Keep classic syntax colors by disabling LSP semantic token highlights.
	client.server_capabilities.semanticTokensProvider = nil

	-- Enable completion triggered by <c-x><c-o>
	vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })

	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	local bufopts = { noremap = true, silent = true, buffer = bufnr }
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
	vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
	vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
	vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, bufopts)
	vim.keymap.set("n", "<space>f", function()
		vim.lsp.buf.format({ async = true })
	end, bufopts)
end

-- this setups every language server automatically
local installed_servers = mason_lspconfig.get_installed_servers()

local function should_enable_server(server)
	if server == "tinymist" then
		return false
	end

	if server == "rust_analyzer" then
		return vim.fn.executable(vim.env.RUSTC or "rustc") == 1
	end

	return true
end

for _, server in ipairs(installed_servers) do
	if should_enable_server(server) then
		vim.lsp.config(server, {
			on_attach = on_attach,
			capabilities = capabilities,
		})
		vim.lsp.enable(server)
	end
end

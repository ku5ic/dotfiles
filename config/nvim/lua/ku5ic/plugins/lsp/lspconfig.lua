-- import lspconfig plugin safely
local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
	return
end

local saga_status, saga = pcall(require, "lspsaga")
if not saga_status then
	return
end

-- import cmp-nvim-lsp plugin safely
local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
	return
end

local keymap = vim.keymap -- for conciseness

-- enable keybinds only for when lsp server available
local on_attach = function()
	-- keybind options
	local opts = { noremap = true, silent = true }

	-- Lsp finder find the symbol definition implement reference
	-- if there is no implement it will hide
	-- when you use action in finder like open vsplit then you can
	-- use <C-t> to jump back
	keymap.set("n", "gh", "<cmd>Lspsaga lsp_finder<CR>", opts)

	-- Code action
	keymap.set({"n","v"}, "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts)

	-- Rename
	keymap.set("n", "gr", "<cmd>Lspsaga rename<CR>", opts)

	-- Peek Definition
	-- you can edit the definition file in this flaotwindow
	-- also support open/vsplit/etc operation check definition_action_keys
	-- support tagstack C-t jump back
	keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>", opts)

	-- Show line diagnostics
	keymap.set("n", "<leader>l", "<cmd>Lspsaga show_line_diagnostics<CR>", opts)

	-- Show cursor diagnostic
	keymap.set("n", "<leader>c", "<cmd>Lspsaga show_cursor_diagnostics<CR>", opts)

	-- Diagnsotic jump can use `<c-o>` to jump back
	keymap.set("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
	keymap.set("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)

	-- Only jump to error
	keymap.set("n", "[E", function()
		saga.goto_prev({ severity = vim.diagnostic.severity.ERROR })
	end, opts)
	keymap.set("n", "]E", function()
		saga.goto_next({ severity = vim.diagnostic.severity.ERROR })
	end, opts)

	-- Outline
	keymap.set("n","<leader>o", "<cmd>LSoutlineToggle<CR>",opts)

	-- Hover Doc
	keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)

	-- Float terminal
	keymap.set("n", "<A-d>", "<cmd>Lspsaga open_floaterm<CR>", opts)
	-- if you want pass somc cli command into terminal you can do like this
	-- open lazygit in lspsaga float terminal
	-- keymap.set("n", "<A-d>", "<cmd>Lspsaga open_floaterm lazygit<CR>", opts)
	-- close floaterm
	keymap.set("t", "<A-d>", [[<C-\><C-n><cmd>Lspsaga close_floaterm<CR>]], opts)
end

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
-- (not in youtube nvim video)
local signs = { Error = " ", Warn = " ", Hint = "ﴞ ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- configure html server
lspconfig["html"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure typescript server with plugin
lspconfig["tsserver"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "typescript", "typescriptreact", "typescript.tsx", "javascriptreact", "javascript" },
})

-- configure ruby server plugin
lspconfig["solargraph"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure css server
lspconfig["cssls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure emmet language server
lspconfig["emmet_ls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
})

-- configure lua server (with special settings)
lspconfig["sumneko_lua"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = { -- custom settings for lua
		Lua = {
			-- make the language server recognize "vim" global
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				-- make language server aware of runtime files
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.stdpath("config") .. "/lua"] = true,
				},
			},
		},
	},
})

# Neovim config

Loads only when working under `config/nvim/`. See the repo root `CLAUDE.md` for the rest of the dotfiles.

## Entry point and layout

Entry point: `init.lua` - bootstraps lazy.nvim, sets leader to `<Space>`, loads `config.options` first (so plugins can read final option state), then `lazy.setup("plugins")`, then keymap modules.

Top-level layout under `lua/`:

- `plugins/` - one file per plugin spec, named after the plugin (e.g. `gitsigns.lua`, `which-key.lua`), auto-discovered by lazy.nvim (top-level files only; subdirectories without `init.lua` are not treated as specs)
- `config/options.lua` - vim options
- `config/icons.lua` - icon set used by lualine, bufferline, diagnostics
- `config/filetypes.lua` - filetype constants (`JS`, `TS`, `JS_TS`, `JS_REACT`, `CSS`, `WEB`) consumed by formatting, linting, and LSP filetype lists
- `lsp/servers/` - per-server LSP settings, one file per server. Adding a server is dropping a file here; `lsp/discovery.lua` discovers them via `readdir` and feeds Mason. Switch TypeScript LSP between `ts_ls`/`vtsls` via the `typescript_lsp` variable in `lsp/discovery.lua`
- `keymaps/keymaps.lua` - global / built-in / cmd-form keymaps (window, tab, buffer, picker, git, LSP, Trouble, copy paths, Neovide). Plugin-specific keymaps live with their plugin spec via lazy `keys = {...}`
- `keymaps/copilotchat.lua` - AI keymaps
- `utils/copilotchat.lua`, `utils/copilotchat/prompts.lua` - CopilotChat helpers and prompt templates

**Plugin files** (one file per plugin spec, named after the plugin):

Notable files and exceptions:

- `mason.lua` - mason.nvim; `mason-lspconfig` and `mason-tool-installer` are declared as `dependencies` inside this spec (not separate files)
- `nvim-lspconfig.lua` - nvim-lspconfig; diagnostic config, server setup, LSP keymaps, codelens autocmd
- `copilot.lua` - GitHub Copilot and CopilotChat.nvim (two specs kept together by design)
- `code-completion.lua` - blink.cmp
- `which-key.lua` - group labels for every `<leader>` prefix live here
- `formatting.lua` / `linting.lua` - conform.nvim / nvim-lint; both consume `config.filetypes` for JS/TS filetype lists
- `snacks.lua` - snacks.nvim (picker, explorer, notifier, input, statuscolumn, toggle, indent, dim, words, scope, scroll, bigfile, quickfile)
- `flash.lua` - flash.nvim (labeled jump via `<leader>j`/`<leader>J`; enhances `/` search and `f`/`t` motions)
- `harpoon.lua` - harpoon2 (curated file marks; `<leader>ha` add, `<leader>hh` menu, `<leader>h1-4` slots)
- `nvim-dap.lua` - nvim-dap; all DAP keymaps colocated via lazy `keys`

**Augroups:**

All custom autocmds belong to a `dotfiles_*` augroup created with `clear = true`, so `:source $MYVIMRC` does not duplicate registrations: `dotfiles_autoreload` (FocusGained/BufEnter checktime), `dotfiles_lsp_attach`, `dotfiles_lsp_codelens`, `dotfiles_treesitter_highlight`, `dotfiles_lint` (linting.lua).

**Keymap prefix conventions** (leader = `<Space>`):

- `<leader><space>` - Smart find (snacks.picker)
- `<leader>e` / `<leader>E` - Explorer toggle / Reveal current file in explorer
- `<leader>f` - Find/files (snacks.picker: files, recent, buffers, config, git-files, projects)
- `<leader>s` - Search (snacks.picker: grep, LSP symbols, diagnostics, help, marks, undo, registers, jumps, man, icons, etc.; grug-far for replace)
- `<leader>g` - Git + GitHub (snacks.picker: status, log, diff, stash, branches; GitHub PRs/issues; Snacks.lazygit; gitsigns hunks; fugitive)
- `<leader>w` - Window splits
- `<leader>t` - Tabs
- `<leader>b` - Buffer management
- `<leader>l` - LSP actions
- `<leader>x` - Trouble diagnostics
- `<leader>d` - DAP debugger (also F5/F10/F11/F12)
- `<leader>a` - AI/Copilot (CopilotChat; see `keymaps/copilotchat.lua`)
- `<leader>A` - AI/Claude Code (coder/claudecode.nvim, default upstream keymaps; see `plugins/claude-code.lua`)
- `<leader>n` - Notifications (notification history picker; snacks notifier, noice, precognition)
- `<leader>u` - UI toggles (spell, wrap, relativenumber, diagnostics, conceallevel, treesitter, background, inlay hints, indent, dim; colorscheme picker)
- `<leader>c` - Copy file path
- `<leader>h` - Harpoon file marks
- `<leader>j` / `<leader>J` - Flash jump / Flash treesitter select

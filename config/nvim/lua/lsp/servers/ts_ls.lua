return {
  init_options = {
    maxTsServerMemory = 8192,
    tsserver = { logVerbosity = "off" },
  },
  settings = {
    typescript = { inlayHints = { enabled = false }, experimental = { useTsgo = true } },
    javascript = { inlayHints = { enabled = false }, experimental = { useTsgo = true } },
  },
  filetypes = {
    "astro",
    "javascript",
    "javascript.jsx",
    "javascriptreact",
    "svelte",
    "typescript",
    "typescript.tsx",
    "typescriptreact",
    "vue",
  },
}

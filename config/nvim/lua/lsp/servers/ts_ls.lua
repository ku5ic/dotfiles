return {
  init_options = {
    maxTsServerMemory = 8192,
    tsserver = { logVerbosity = "off" },
  },
  settings = {
    typescript = {
      inlayHints = {
        parameterNames = {
          enabled = "literals",
          suppressWhenArgumentMatchesName = true,
        },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
      experimental = { useTsgo = true },
    },
    javascript = {
      inlayHints = {
        parameterNames = {
          enabled = "literals",
          suppressWhenArgumentMatchesName = true,
        },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
      experimental = { useTsgo = true },
    },
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

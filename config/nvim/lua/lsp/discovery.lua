-- Toggle between TypeScript LSP servers: "ts_ls" or "vtsls"
-- Change typescript_lsp here to switch; the inactive server is filtered out automatically.
local M = {}

M.typescript_lsp = "ts_ls"

local function discover_server_names()
  local dir = vim.fn.stdpath("config") .. "/lua/lsp/servers"
  local files = vim.fn.readdir(dir)
  local names = {}
  for _, file in ipairs(files) do
    if file:match("%.lua$") then
      local name = file:gsub("%.lua$", "")
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end

-- Cached so mason and lspconfig receive the identical list from one filesystem read.
local _cache = nil

function M.active_server_names()
  if _cache then
    return _cache
  end
  local skip = M.typescript_lsp == "vtsls" and "ts_ls" or "vtsls"
  local result = {}
  for _, name in ipairs(discover_server_names()) do
    if name ~= skip then
      table.insert(result, name)
    end
  end
  _cache = result
  return result
end

function M.get_server_settings(name)
  local ok, settings = pcall(require, "lsp.servers." .. name)
  return ok and settings or {}
end

return M

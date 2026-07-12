-- Shared keymap registration helper.
--
-- Merges the standard {noremap, silent} defaults with any per-call extras and
-- sets the description. The per-call tbl_extend deliberately does not close over
-- a shared opts table, so callers cannot mutate each other's options.
local M = {}

function M.map(mode, lhs, rhs, desc, extra_opts)
  local opts = vim.tbl_extend("force", { noremap = true, silent = true }, extra_opts or {})
  opts.desc = desc
  vim.keymap.set(mode, lhs, rhs, opts)
end

return M

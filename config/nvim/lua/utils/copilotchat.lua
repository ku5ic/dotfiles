local M = {}

-- Prompt templates live in utils/copilotchat/prompts.lua.
local prompts_module = require("utils.copilotchat.prompts")

local uv = vim.uv or vim.loop

M.prompts = prompts_module.prompts

local CONTEXT_TAGS = {
  SELECTION = "#selection",
  BUFFER = "#buffer:active",
}

local function is_visual_mode()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22"
end

-- vim.uv.fs_stat avoids the Vimscript overhead of vim.fn.filereadable.
local function file_exists(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  local stat = (uv and uv.fs_stat) and uv.fs_stat(path) or nil
  return stat ~= nil and stat.type == "file"
end

local function normalize_path(path)
  return vim.fn.fnamemodify(path, ":p")
end

local function project_root()
  return normalize_path(vim.fn.getcwd())
end

local function current_buffer_path()
  local name = vim.api.nvim_buf_get_name(0)
  if not name or name == "" then
    return nil
  end
  return normalize_path(name)
end

local function path_relative_to_root(path, root)
  local escaped_root = vim.pesc(root)
  return path:gsub("^" .. escaped_root .. "/?", "")
end

local function add_unique_tag(tags, seen, tag)
  if type(tag) ~= "string" or tag == "" then
    return
  end
  if not seen[tag] then
    seen[tag] = true
    table.insert(tags, tag)
  end
end

-- Finds `names` at the project root and in every directory between the
-- current buffer and the root (e.g. README.md, CLAUDE.md).
local function collect_doc_tags(names)
  local root = project_root()
  local tags = {}
  local seen = {}

  local function check_dir(dir)
    for _, name in ipairs(names) do
      local candidate = dir .. "/" .. name
      if file_exists(candidate) then
        add_unique_tag(tags, seen, "#file:" .. path_relative_to_root(candidate, root))
      end
    end
  end

  check_dir(root)

  local buf_path = current_buffer_path()
  if buf_path then
    local dir = vim.fn.fnamemodify(buf_path, ":p:h")
    local root_with_sep = root .. "/"
    while dir and dir ~= "" and dir ~= root and vim.startswith(dir .. "/", root_with_sep) do
      check_dir(dir)
      local parent = vim.fn.fnamemodify(dir, ":h")
      if parent == dir then
        break
      end
      dir = parent
    end
  end

  return tags
end

local function build_context_tags(opts)
  opts = opts or {}

  local tags = {}
  local seen = {}

  if opts.context and #opts.context > 0 then
    for _, tag in ipairs(opts.context) do
      add_unique_tag(tags, seen, tag)
    end
  elseif opts.selection_only and is_visual_mode() then
    add_unique_tag(tags, seen, CONTEXT_TAGS.SELECTION)
  else
    add_unique_tag(tags, seen, CONTEXT_TAGS.BUFFER)
  end

  if type(opts.dynamic_context) == "table" then
    for _, tag in ipairs(collect_doc_tags(opts.dynamic_context)) do
      add_unique_tag(tags, seen, tag)
    end
  end

  return tags
end

local function build_prompt(user_prompt, opts)
  local tags = build_context_tags(opts)
  return string.format("%s\n\nContext:\n%s", user_prompt or "", table.concat(tags, "\n"))
end

-- opts: system_prompt, model, context (list of tags), dynamic_context (list of
-- filenames to find via collect_doc_tags), selection_only.
function M.ask(user_prompt, opts)
  local ok, mod = pcall(require, "CopilotChat")
  if not ok or type(mod.ask) ~= "function" then
    vim.notify("[CopilotChat] Plugin not loaded or 'ask' API unavailable.", vim.log.levels.ERROR)
    return false
  end

  opts = opts or {}

  local prompt = build_prompt(user_prompt, opts)

  local ask_opts = {
    window = { title = "CopilotChat" },
  }

  if opts.system_prompt then
    ask_opts.system_prompt = opts.system_prompt
  end

  if opts.model then
    ask_opts.model = opts.model
  end

  local success, err = pcall(mod.ask, prompt, ask_opts)

  if not success then
    vim.notify("[CopilotChat] Failed to send prompt: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

-- Sends a named prompt template (M.prompts) to CopilotChat; opts overrides/extends it.
function M.prompt(name, opts)
  local prompt_def = M.prompts[name]

  if not prompt_def then
    vim.notify(string.format("[CopilotChat] Unknown prompt: '%s'", name), vim.log.levels.WARN)
    return false
  end

  if type(prompt_def) == "string" then
    return M.ask(prompt_def, opts)
  end

  if type(prompt_def) == "table" and type(prompt_def.prompt) == "string" then
    ---@cast prompt_def { prompt: string, system_prompt: string|nil, context: string[]|nil, dynamic_context: table|nil }
    local merged_opts = vim.tbl_extend("force", opts or {}, {
      system_prompt = prompt_def.system_prompt,
      context = prompt_def.context,
      dynamic_context = prompt_def.dynamic_context,
      model = prompt_def.model,
    })
    return M.ask(prompt_def.prompt, merged_opts)
  end

  vim.notify(string.format("[CopilotChat] Invalid prompt definition for '%s'", name), vim.log.levels.ERROR)
  return false
end

return M

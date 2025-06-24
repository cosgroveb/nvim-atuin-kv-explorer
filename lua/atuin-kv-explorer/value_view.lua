-- Value display view

local M = {}

--- Show value for a key in buffer
---@param bufnr number Buffer number
---@param namespace string Namespace name
---@param key string Key name
function M.show_value(bufnr, namespace, key)
  -- Get value
  local atuin = require "atuin-kv-explorer.atuin"
  local result = atuin.get_value(namespace, key)

  if not result.success then
    vim.notify("Failed to get value: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Display value
  local keyvalue = result.data
  local buffer = require "atuin-kv-explorer.buffer"
  buffer.display(bufnr, keyvalue.value)
end

return M

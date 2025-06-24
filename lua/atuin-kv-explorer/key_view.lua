-- Key explorer view

local M = {}

--- Show keys for a namespace in buffer
---@param bufnr number Buffer number
---@param namespace string Namespace name
function M.show_keys(bufnr, namespace)
  -- Get key list
  local atuin = require "atuin-kv-explorer.atuin"
  local result = atuin.list_keys(namespace)

  if not result.success then
    local buffer = require "atuin-kv-explorer.buffer"
    buffer.display_lines(bufnr, { "Error: " .. (result.error or "Failed to list keys") })
    return
  end

  -- Display keys
  local lines = {}
  if #result.data == 0 then
    table.insert(lines, "No keys found in namespace: " .. namespace)
  else
    for _, key in ipairs(result.data) do
      table.insert(lines, key)
    end
  end

  local buffer = require "atuin-kv-explorer.buffer"
  buffer.display_lines(bufnr, lines)
end

--- Get current key under cursor
---@return string|nil Key name
function M.get_current_key()
  local line = vim.api.nvim_get_current_line()
  local key = line:match "^%s*(.-)%s*$"

  if not key or key == "" or key:match "^No keys found" then
    return nil
  end

  return key
end

--- Refresh keys view
---@param bufnr number Buffer number
---@param namespace string Namespace name
function M.refresh_keys(bufnr, namespace)
  M.show_keys(bufnr, namespace)
end

return M

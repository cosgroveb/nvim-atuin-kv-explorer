-- Namespace explorer view

local M = {}

--- Show namespaces in buffer
---@param bufnr number Buffer number
function M.show_namespaces(bufnr)
  -- Get namespace list
  local atuin = require "atuin-kv-explorer.atuin"
  local result = atuin.list_namespaces()

  if not result.success then
    local buffer = require "atuin-kv-explorer.buffer"
    buffer.display_lines(bufnr, { "Error: " .. (result.error or "Failed to list namespaces") })
    return
  end

  -- Display namespaces
  local lines = {}
  if #result.data == 0 then
    table.insert(lines, "No namespaces found")
  else
    for _, namespace in ipairs(result.data) do
      table.insert(lines, namespace)
    end
  end

  local buffer = require "atuin-kv-explorer.buffer"
  buffer.display_lines(bufnr, lines)
end

--- Get current namespace under cursor
---@return string|nil Namespace name
function M.get_current_namespace()
  local line = vim.api.nvim_get_current_line()
  local namespace = line:match "^%s*(.-)%s*$"

  if not namespace or namespace == "" or namespace == "No namespaces found" then
    return nil
  end

  return namespace
end

--- Refresh namespaces view
---@param bufnr number Buffer number
function M.refresh_namespaces(bufnr)
  M.show_namespaces(bufnr)
end

return M

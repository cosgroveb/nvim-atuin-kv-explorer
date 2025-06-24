-- Generic list view for namespaces and keys

local M = {}

--- Show list of items in buffer
---@param bufnr number Buffer number
---@param items table Array of items to display
---@param empty_message string Message to show when no items
function M.show_list(bufnr, items, empty_message)
  local content
  if #items == 0 then
    content = empty_message or "No items found"
  else
    content = table.concat(items, "\n")
  end

  local buffer = require "atuin-kv-explorer.buffer"
  buffer.display(bufnr, content)
end

--- Get current item under cursor
---@return string|nil Item name
function M.get_current_item()
  local line = vim.api.nvim_get_current_line()
  local item = line:match "^%s*(.-)%s*$"

  if not item or item == "" or item:match "^No.*found" then
    return nil
  end

  return item
end

return M

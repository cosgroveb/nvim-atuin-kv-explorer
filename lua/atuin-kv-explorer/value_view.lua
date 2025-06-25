-- Value display view

local M = {}

--- Show value for a key in editable buffer
---@param bufnr number Buffer number (ignored, we create our own editable buffer)
---@param namespace string Namespace name
---@param key string Key name
function M.show_value(_bufnr, namespace, key)
  -- Get value from atuin kv
  local atuin = require "atuin-kv-explorer.atuin"
  local result = atuin.get_value(namespace, key)

  local initial_content = ""

  if result.success then
    -- Key exists, use its current value
    initial_content = result.data.value or ""
  else
    -- Key doesn't exist, create empty editable buffer for new key creation
    vim.notify(string.format("Key %s/%s does not exist, creating new key", namespace, key), vim.log.levels.INFO)
  end

  -- Create editable buffer
  local buffer = require "atuin-kv-explorer.buffer"
  local edit_bufnr = buffer.create_editable_buffer(namespace, key, initial_content)

  -- Open buffer in current window
  vim.api.nvim_set_current_buf(edit_bufnr)
end

return M

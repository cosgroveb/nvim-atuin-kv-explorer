-- Buffer management for atuin-kv-explorer

local M = {}

--- Create buffer with common configuration
---@param buffer_type string "explorer" or "editable"
---@param name string Buffer name
---@param initial_content string|nil Initial content for editable buffers
---@return number Buffer number
local function create_buffer(buffer_type, name, initial_content)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local opts = {
    swapfile = false,
  }

  if buffer_type == "explorer" then
    opts.buftype = "nofile"
    opts.bufhidden = "wipe"
    opts.buflisted = false
    opts.modifiable = false
    opts.filetype = "atuin-kv-explorer"
  else -- editable
    opts.buftype = ""
    opts.buflisted = true
    opts.modifiable = true
    opts.filetype = "text"
  end

  for option, value in pairs(opts) do
    vim.api.nvim_set_option_value(option, value, { buf = bufnr })
  end

  vim.api.nvim_buf_set_name(bufnr, name)

  if buffer_type == "explorer" then
    local keymap_opts = { buffer = bufnr, silent = true, noremap = true }
    vim.keymap.set("n", "q", function()
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
  elseif initial_content and initial_content ~= "" then
    local lines = vim.split(initial_content, "\n")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
  end

  return bufnr
end

--- Create new explorer buffer
---@return number Buffer number
function M.create_explorer_buffer()
  local name = "Atuin KV Explorer " .. vim.fn.localtime()
  return create_buffer("explorer", name)
end

--- Display content in buffer
---@param bufnr number Buffer number
---@param content string Content to display
function M.display(bufnr, content)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Make buffer modifiable temporarily
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })

  -- Split content into lines and set buffer contents
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Make buffer read-only again
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

--- Create editable buffer for atuin kv values
---@param namespace string Namespace name
---@param key string Key name
---@param initial_content string Initial content for the buffer
---@return number Buffer number
function M.create_editable_buffer(namespace, key, initial_content)
  if not namespace or namespace == "" or not key or key == "" then
    error "Namespace and key cannot be empty"
  end

  local buffer_name = string.format("atuin-kv://%s/%s", namespace, key)
  local existing_bufnr = vim.fn.bufnr(buffer_name)

  if existing_bufnr ~= -1 and vim.api.nvim_buf_is_valid(existing_bufnr) then
    vim.api.nvim_set_current_buf(existing_bufnr)
    return existing_bufnr
  end

  local bufnr = create_buffer("editable", buffer_name, initial_content)
  M.setup_save_autocmd(bufnr)
  M.setup_modification_tracking(bufnr)
  return bufnr
end

--- Get namespace and key from buffer metadata
---@param bufnr number Buffer number
---@return string|nil namespace
---@return string|nil key
function M.get_buffer_metadata(bufnr)
  local buffer_name = vim.api.nvim_buf_get_name(bufnr)

  -- Parse atuin-kv://namespace/key format
  local namespace, key = buffer_name:match "^atuin%-kv://([^/]+)/(.+)$"

  return namespace, key
end

--- Setup save autocmd for a buffer
---@param bufnr number Buffer number
function M.setup_save_autocmd(bufnr)
  -- Only set up autocmd for atuin-kv buffers
  local namespace, key = M.get_buffer_metadata(bufnr)
  if not namespace or not key then
    return
  end

  -- Create autocmd for this specific buffer
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function()
      M.handle_save_request(bufnr)
    end,
    desc = "Handle save for atuin kv buffer",
  })
end

--- Setup modification tracking for a buffer
---@param bufnr number Buffer number
function M.setup_modification_tracking(bufnr)
  -- Mark buffer as modified when content changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = bufnr,
    callback = function()
      vim.api.nvim_set_option_value("modified", true, { buf = bufnr })
    end,
    desc = "Mark atuin kv buffer as modified",
  })
end

--- Handle save request - save buffer content to atuin kv
---@param bufnr number Buffer number
function M.handle_save_request(bufnr)
  local namespace, key = M.get_buffer_metadata(bufnr)

  if not namespace or not key then
    vim.notify("Invalid atuin kv buffer", vim.log.levels.ERROR)
    return
  end

  -- Extract buffer content (preserve exact formatting)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- Save to atuin kv store
  local atuin = require "atuin-kv-explorer.atuin"
  local result = atuin.set_value(namespace, key, content)

  if result.success then
    -- Mark buffer as saved
    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })

    -- Show success message matching Vim's file save format
    local line_count = #lines
    local word = line_count == 1 and "line" or "lines"
    vim.notify(string.format('"%s" %d %s written', vim.api.nvim_buf_get_name(bufnr), line_count, word))
  else
    -- Show error and keep buffer marked as unsaved
    local error_msg = result.error or "Unknown error"
    vim.notify(string.format("Failed to save %s/%s: %s", namespace, key, error_msg), vim.log.levels.ERROR)
    -- Keep modified flag set so :q warns about unsaved changes
  end
end

return M

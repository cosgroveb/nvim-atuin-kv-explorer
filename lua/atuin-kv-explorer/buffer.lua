-- Buffer management for atuin-kv-explorer

local M = {}

--- Create new explorer buffer
---@return number Buffer number
function M.create_explorer_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Configure buffer options
  local opts = {
    buftype = "nofile",
    bufhidden = "wipe",
    swapfile = false,
    buflisted = false,
    modifiable = false,
    filetype = "atuin-kv-explorer",
  }

  for option, value in pairs(opts) do
    vim.api.nvim_set_option_value(option, value, { buf = bufnr })
  end

  -- Set buffer name with unique suffix to avoid conflicts
  local name = "Atuin KV Explorer " .. bufnr
  vim.api.nvim_buf_set_name(bufnr, name)

  -- Setup keymaps
  local keymap_opts = { buffer = bufnr, silent = true, noremap = true }
  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end, keymap_opts)

  vim.keymap.set("n", "<CR>", function()
    M.select_item(bufnr)
  end, keymap_opts)

  vim.keymap.set("n", "<BS>", function()
    M.go_back(bufnr)
  end, keymap_opts)

  return bufnr
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

--- Clear buffer contents
---@param bufnr number Buffer number
function M.clear_buffer(bufnr)
  M.display(bufnr, "")
end

--- Select item under cursor
---@param _bufnr number Buffer number
function M.select_item(_bufnr)
  local line = vim.api.nvim_get_current_line()
  vim.notify("Selected: " .. line, vim.log.levels.INFO)
end

--- Go back/up one level
---@param _bufnr number Buffer number
function M.go_back(_bufnr)
  vim.notify("Go back", vim.log.levels.INFO)
end

--- Create editable buffer for atuin kv values
---@param namespace string Namespace name
---@param key string Key name
---@param initial_content string Initial content for the buffer
---@return number Buffer number
function M.create_editable_buffer(namespace, key, initial_content)
  -- Check if buffer already exists for this namespace/key
  local buffer_name = string.format("atuin-kv://%s/%s", namespace, key)
  local existing_bufnr = vim.fn.bufnr(buffer_name)

  if existing_bufnr ~= -1 and vim.api.nvim_buf_is_valid(existing_bufnr) then
    -- Switch to existing buffer
    vim.api.nvim_set_current_buf(existing_bufnr)
    return existing_bufnr
  end

  -- Create new buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Configure buffer options for editing
  local opts = {
    buftype = "",
    swapfile = false,
    buflisted = true,
    modifiable = true,
    filetype = "text",
  }

  for option, value in pairs(opts) do
    vim.api.nvim_set_option_value(option, value, { buf = bufnr })
  end

  -- Set buffer name
  vim.api.nvim_buf_set_name(bufnr, buffer_name)

  -- Set initial content
  if initial_content and initial_content ~= "" then
    local lines = vim.split(initial_content, "\n")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    -- Mark as unmodified since this is the initial state
    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
  end

  -- Setup save detection
  M.setup_save_autocmd(bufnr)

  -- Setup modification tracking
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

--- Handle save request (stub for now, will be completed in step 2)
---@param bufnr number Buffer number
function M.handle_save_request(bufnr)
  local namespace, key = M.get_buffer_metadata(bufnr)

  if not namespace or not key then
    vim.notify("Invalid atuin kv buffer", vim.log.levels.ERROR)
    return
  end

  -- Extract buffer content
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- For now, just log the save attempt
  vim.notify(
    string.format("Save request: %s/%s (%d lines, %d chars)", namespace, key, #lines, #content),
    vim.log.levels.INFO
  )

  -- TODO: Implement actual save to atuin kv in step 2
  -- For now, mark as saved to test the flow
  vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
end

return M

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

return M

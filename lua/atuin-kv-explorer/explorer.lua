-- Main explorer interface

local M = {}

-- State tracking
local explorer_state = {
  bufnr = nil,
  mode = "namespaces", -- "namespaces" | "keys" | "value"
  current_namespace = nil,
  current_key = nil,
}

--- Open the explorer
function M.open()
  -- Create buffer and window
  local buffer = require "atuin-kv-explorer.buffer"
  local bufnr = buffer.create_explorer_buffer()

  -- Open in new window
  vim.cmd "split"
  vim.api.nvim_win_set_buf(0, bufnr)

  -- Initialize state
  explorer_state.bufnr = bufnr
  explorer_state.mode = "namespaces"
  explorer_state.current_namespace = nil
  explorer_state.current_key = nil

  -- Override buffer keymaps with explorer-specific ones
  local opts = { buffer = bufnr, silent = true, noremap = true }
  vim.keymap.set("n", "<CR>", M.select_item, opts)
  vim.keymap.set("n", "<BS>", M.go_back, opts)

  -- Show initial view
  M.refresh()
end

--- Select item under cursor
function M.select_item()
  local list_view = require "atuin-kv-explorer.list_view"
  local item = list_view.get_current_item()

  if not item then
    return
  end

  if explorer_state.mode == "namespaces" then
    explorer_state.current_namespace = item
    explorer_state.mode = "keys"
    M.refresh()
  elseif explorer_state.mode == "keys" then
    explorer_state.current_key = item
    explorer_state.mode = "value"
    M.refresh()
  end
end

--- Go back one level
function M.go_back()
  if explorer_state.mode == "value" then
    explorer_state.mode = "keys"
    explorer_state.current_key = nil
    M.refresh()
  elseif explorer_state.mode == "keys" then
    explorer_state.mode = "namespaces"
    explorer_state.current_namespace = nil
    M.refresh()
  end
end

--- Refresh current view
function M.refresh()
  if not explorer_state.bufnr or not vim.api.nvim_buf_is_valid(explorer_state.bufnr) then
    return
  end

  if explorer_state.mode == "namespaces" then
    local atuin = require "atuin-kv-explorer.atuin"
    local result = atuin.list_namespaces()

    if not result.success then
      vim.notify("Failed to list namespaces: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
      return
    end

    local list_view = require "atuin-kv-explorer.list_view"
    list_view.show_list(explorer_state.bufnr, result.data, "No namespaces found")
  elseif explorer_state.mode == "keys" and explorer_state.current_namespace then
    local atuin = require "atuin-kv-explorer.atuin"
    local result = atuin.list_keys(explorer_state.current_namespace)

    if not result.success then
      vim.notify("Failed to list keys: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
      return
    end

    local list_view = require "atuin-kv-explorer.list_view"
    list_view.show_list(
      explorer_state.bufnr,
      result.data,
      "No keys found in namespace: " .. explorer_state.current_namespace
    )
  elseif explorer_state.mode == "value" and explorer_state.current_namespace and explorer_state.current_key then
    local value_view = require "atuin-kv-explorer.value_view"
    value_view.show_value(explorer_state.bufnr, explorer_state.current_namespace, explorer_state.current_key)
  end
end

return M

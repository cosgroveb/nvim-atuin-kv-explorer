-- Main module for atuin-kv-explorer plugin

local M = {}

-- Default configuration
local default_config = {
  enabled = true,
}

-- Module state
local config = {}
local is_setup = false

-- Explorer state tracking
local explorer_state = {
  bufnr = nil,
  mode = "namespaces", -- "namespaces" | "keys" | "value"
  current_namespace = nil,
  current_key = nil,
}

--- Setup the plugin with user configuration
---@param opts table|nil User configuration options
function M.setup(opts)
  opts = opts or {}

  -- Merge with defaults using config module
  local config_module = require "atuin-kv-explorer.config"
  local ok, merged_config = pcall(config_module.merge_config, default_config, opts)

  if not ok then
    vim.notify("atuin-kv-explorer: Failed to setup configuration", vim.log.levels.ERROR)
    return
  end

  config = merged_config
  is_setup = true

  -- Note: Telescope extension loading is deferred to runtime to handle lazy loading

  vim.notify("atuin-kv-explorer: Plugin initialized", vim.log.levels.INFO)
end

--- Get current configuration
---@return table Current configuration
function M.get_config()
  return config or default_config
end

--- Check if plugin is properly setup
---@return boolean Setup status
function M.is_setup()
  return is_setup
end

--- Explorer functions (integrated from explorer.lua)
local function explorer_select_item()
  local line = vim.api.nvim_get_current_line()
  local item = line:match "^%s*(.-)%s*$"

  if not item or item == "" or item:match "^No.*found" then
    return
  end

  if explorer_state.mode == "namespaces" then
    explorer_state.current_namespace = item
    explorer_state.mode = "keys"
    M.explorer_refresh()
  elseif explorer_state.mode == "keys" then
    explorer_state.current_key = item
    explorer_state.mode = "value"
    M.explorer_refresh()
  end
end

local function explorer_go_back()
  if explorer_state.mode == "value" then
    explorer_state.mode = "keys"
    explorer_state.current_key = nil
    M.explorer_refresh()
  elseif explorer_state.mode == "keys" then
    explorer_state.mode = "namespaces"
    explorer_state.current_namespace = nil
    M.explorer_refresh()
  end
end

function M.explorer_refresh()
  if not explorer_state.bufnr or not vim.api.nvim_buf_is_valid(explorer_state.bufnr) then
    return
  end

  local buffer = require "atuin-kv-explorer.buffer"
  local atuin = require "atuin-kv-explorer.atuin"

  if explorer_state.mode == "namespaces" then
    local result = atuin.list_namespaces()
    if not result.success then
      vim.notify("Failed to list namespaces: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
      return
    end
    local content = #result.data == 0 and "No namespaces found" or table.concat(result.data, "\n")
    buffer.display(explorer_state.bufnr, content)
  elseif explorer_state.mode == "keys" and explorer_state.current_namespace then
    local result = atuin.list_keys(explorer_state.current_namespace)
    if not result.success then
      vim.notify("Failed to list keys: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
      return
    end
    local content = #result.data == 0 and ("No keys found in namespace: " .. explorer_state.current_namespace)
      or table.concat(result.data, "\n")
    buffer.display(explorer_state.bufnr, content)
  elseif explorer_state.mode == "value" and explorer_state.current_namespace and explorer_state.current_key then
    local result = atuin.get_value(explorer_state.current_namespace, explorer_state.current_key)
    local initial_content = result.success and result.data.value or ""
    if not result.success then
      vim.notify(
        string.format(
          "Key %s/%s does not exist, creating new key",
          explorer_state.current_namespace,
          explorer_state.current_key
        ),
        vim.log.levels.INFO
      )
    end
    local edit_bufnr =
      buffer.create_editable_buffer(explorer_state.current_namespace, explorer_state.current_key, initial_content)
    vim.api.nvim_set_current_buf(edit_bufnr)
  end
end

function M.open_explorer_buffer()
  local buffer = require "atuin-kv-explorer.buffer"
  local bufnr = buffer.create_explorer_buffer()

  vim.cmd "split"
  vim.api.nvim_win_set_buf(0, bufnr)

  explorer_state.bufnr = bufnr
  explorer_state.mode = "namespaces"
  explorer_state.current_namespace = nil
  explorer_state.current_key = nil

  -- Override buffer keymaps with explorer-specific ones
  local opts = { buffer = bufnr, silent = true, noremap = true }
  vim.keymap.set("n", "<CR>", explorer_select_item, opts)
  vim.keymap.set("n", "<BS>", explorer_go_back, opts)

  M.explorer_refresh()
end

--- Open explorer interface (auto-detects telescope or buffer mode)
function M.open_explorer()
  local config_module = require "atuin-kv-explorer.config"
  local ui_mode = config_module.get_ui_mode(config)

  if ui_mode == "telescope" then
    local telescope = require "telescope"
    if not telescope.extensions.atuin_kv then
      telescope.load_extension "atuin_kv"
    end
    telescope.extensions.atuin_kv.namespaces()
  else
    M.open_explorer_buffer()
  end
end

--- Open telescope namespace picker
function M.telescope_namespaces()
  if pcall(require, "telescope") then
    local telescope = require "telescope"
    if not telescope.extensions.atuin_kv then
      telescope.load_extension "atuin_kv"
    end
    telescope.extensions.atuin_kv.namespaces()
  else
    vim.notify("Telescope is not available", vim.log.levels.ERROR)
  end
end

--- Open telescope search across all keys
function M.telescope_search()
  if pcall(require, "telescope") then
    local telescope = require "telescope"
    if not telescope.extensions.atuin_kv then
      telescope.load_extension "atuin_kv"
    end
    telescope.extensions.atuin_kv.search()
  else
    vim.notify("Telescope is not available", vim.log.levels.ERROR)
  end
end

return M

-- Main module for atuin-kv-explorer plugin

local M = {}

-- Default configuration
local default_config = {
  -- Configuration will be expanded in config.lua
  enabled = true,
}

-- Module state
local config = {}
local is_setup = false

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

return M

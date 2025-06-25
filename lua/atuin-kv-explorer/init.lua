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

--- Open explorer interface (auto-detects telescope or buffer mode)
function M.open_explorer()
  local config_module = require "atuin-kv-explorer.config"
  local ui_mode = config_module.get_ui_mode(config)

  if ui_mode == "telescope" then
    -- Load telescope extension at runtime if not already loaded
    local telescope = require "telescope"
    if not telescope.extensions.atuin_kv then
      telescope.load_extension "atuin_kv"
    end
    telescope.extensions.atuin_kv.namespaces()
  else
    require("atuin-kv-explorer.explorer").open()
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

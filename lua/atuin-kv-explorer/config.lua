-- Configuration module for atuin-kv-explorer

local M = {}

-- Default configuration values
M.defaults = {
  enabled = true,
  ui_mode = "telescope", -- "telescope" or "buffer"
  keymaps = {
    quit = "q",
    refresh = "r",
    select = "<CR>",
    back = "<BS>",
  },
}

--- Validate configuration options
---@param config table Configuration to validate
---@return boolean, string|nil Valid status and error message
local function validate_config(config)
  if type(config) ~= "table" then
    return false, "Configuration must be a table"
  end

  if config.enabled ~= nil and type(config.enabled) ~= "boolean" then
    return false, "enabled must be a boolean"
  end

  if config.keymaps and type(config.keymaps) ~= "table" then
    return false, "keymaps must be a table"
  end

  return true, nil
end

--- Merge user configuration with defaults
---@param defaults table Default configuration
---@param user_config table User configuration
---@return table Merged configuration
function M.merge_config(defaults, user_config)
  local ok, err = validate_config(user_config)
  if not ok then
    error("Invalid configuration: " .. err)
  end

  return vim.tbl_deep_extend("force", defaults, user_config)
end

--- Get default configuration
---@return table Default configuration
function M.get_defaults()
  return vim.deepcopy(M.defaults)
end

--- Check if telescope UI mode is enabled and available
---@param config table Configuration object
---@return boolean True if telescope mode should be used
function M.use_telescope(config)
  return config.ui_mode == "telescope" and pcall(require, "telescope")
end

return M

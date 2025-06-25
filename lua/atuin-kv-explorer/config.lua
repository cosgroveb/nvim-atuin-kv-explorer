-- Configuration module for atuin-kv-explorer

local M = {}

-- Default configuration values
M.defaults = {
  enabled = true,
  ui_mode = "auto", -- "auto", "telescope", or "buffer"
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

--- Determine which UI mode to use based on configuration and availability
---@param config table Configuration object
---@return string UI mode to use: "telescope" or "buffer"
function M.get_ui_mode(config)
  if config.ui_mode == "auto" then
    -- Auto-detect: prefer telescope, then buffer
    if pcall(require, "telescope") then
      return "telescope"
    else
      return "buffer"
    end
  elseif config.ui_mode == "telescope" then
    if pcall(require, "telescope") then
      return "telescope"
    else
      vim.notify("telescope not available, falling back to buffer mode", vim.log.levels.WARN)
      return "buffer"
    end
  else
    return "buffer"
  end
end

--- Check if telescope UI mode should be used
---@param config table Configuration object
---@return boolean True if telescope mode should be used
function M.use_telescope(config)
  return M.get_ui_mode(config) == "telescope"
end

return M

-- Configuration module for atuin-kv-explorer

local M = {}

M.defaults = {
  enabled = true,
  ui_mode = "auto", -- "auto", "telescope", or "buffer"
}

--- Merge user configuration with defaults
---@param defaults table Default configuration
---@param user_config table User configuration
---@return table Merged configuration
function M.merge_config(defaults, user_config)
  if type(user_config) ~= "table" then
    error "Configuration must be a table"
  end
  return vim.tbl_deep_extend("force", defaults, user_config)
end

--- Determine which UI mode to use based on configuration and availability
---@param config table Configuration object
---@return string UI mode to use: "telescope" or "buffer"
function M.get_ui_mode(config)
  if config.ui_mode == "auto" then
    return pcall(require, "telescope") and "telescope" or "buffer"
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

return M

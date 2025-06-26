-- Atuin CLI integration module

local M = {}

--- Validate string parameter
---@param param any Parameter to validate
---@param param_name string Parameter name for error message
---@return boolean, string|nil Valid status and error message
local function validate_string_param(param, param_name)
  if not param or type(param) ~= "string" or param == "" then
    return false, param_name .. " must be a non-empty string"
  end
  return true, nil
end

--- Execute atuin kv command safely
---@param args table List of command arguments
---@return table Result with success, data, and error fields
function M.execute_atuin_command(args)
  if type(args) ~= "table" then
    return {
      success = false,
      data = "",
      error = "Arguments must be a table",
    }
  end

  -- Build command string with proper escaping
  local cmd_parts = { "atuin", "kv" }
  for _, arg in ipairs(args) do
    if type(arg) == "string" then
      table.insert(cmd_parts, vim.fn.shellescape(arg))
    else
      return {
        success = false,
        data = "",
        error = "All arguments must be strings",
      }
    end
  end

  local cmd = table.concat(cmd_parts, " ")

  -- Execute command
  local ok, output = pcall(vim.fn.system, cmd)
  if not ok then
    return {
      success = false,
      data = "",
      error = "Failed to execute command: " .. tostring(output),
    }
  end

  -- Check command exit status
  local exit_code = vim.v.shell_error
  if exit_code ~= 0 then
    return {
      success = false,
      data = output,
      error = "Command failed with exit code " .. exit_code,
    }
  end

  return {
    success = true,
    data = output,
    error = nil,
  }
end

--- List all namespaces
---@return table Result with namespace list
function M.list_namespaces()
  local result = M.execute_atuin_command { "list", "--all-namespaces" }
  if not result.success then
    return result
  end

  -- Parse namespace list using models
  local models = require "atuin-kv-explorer.models"
  local namespaces = models.parse_namespace_list(result.data)

  return {
    success = true,
    data = namespaces,
    error = nil,
  }
end

--- List keys in a namespace
---@param namespace string Namespace name
---@return table Result with key list
function M.list_keys(namespace)
  local ok, err = validate_string_param(namespace, "Namespace")
  if not ok then
    return {
      success = false,
      data = {},
      error = err,
    }
  end

  local result = M.execute_atuin_command { "list", "--namespace", namespace }
  if not result.success then
    return result
  end

  -- Parse key list using models
  local models = require "atuin-kv-explorer.models"
  local keys = models.parse_key_list(result.data)

  return {
    success = true,
    data = keys,
    error = nil,
  }
end

--- Get value for a specific key
---@param namespace string Namespace name
---@param key string Key name
---@return table Result with key value
function M.get_value(namespace, key)
  local ok, err = validate_string_param(namespace, "Namespace")
  if not ok then
    return {
      success = false,
      data = nil,
      error = err,
    }
  end

  ok, err = validate_string_param(key, "Key")
  if not ok then
    return {
      success = false,
      data = nil,
      error = err,
    }
  end

  local result = M.execute_atuin_command { "get", "--namespace", namespace, key }
  if not result.success then
    return result
  end

  -- Parse key value using models
  local models = require "atuin-kv-explorer.models"
  local keyvalue = models.parse_key_value(result.data, namespace, key)

  return {
    success = true,
    data = keyvalue,
    error = nil,
  }
end

--- Set value for a specific key
---@param namespace string Namespace name
---@param key string Key name
---@param value string Value content to save
---@return table Result with success status and error information
function M.set_value(namespace, key, value)
  local ok, err = validate_string_param(namespace, "Namespace")
  if not ok then
    return {
      success = false,
      data = nil,
      error = err,
    }
  end

  ok, err = validate_string_param(key, "Key")
  if not ok then
    return {
      success = false,
      data = nil,
      error = err,
    }
  end

  if type(value) ~= "string" then
    return {
      success = false,
      data = nil,
      error = "Value must be a string",
    }
  end

  local result = M.execute_atuin_command { "set", "--namespace", namespace, "--key", key, value }
  if not result.success then
    return {
      success = false,
      data = nil,
      error = result.error,
    }
  end

  return {
    success = true,
    data = { namespace = namespace, key = key, value = value },
    error = nil,
  }
end

--- Delete a key
---@param namespace string Namespace name
---@param key string Key name
---@return table Result with success status and error information
function M.delete_value(namespace, key)
  local ok, err = validate_string_param(namespace, "Namespace")
  if not ok then
    return {
      success = false,
      error = err,
    }
  end

  ok, err = validate_string_param(key, "Key")
  if not ok then
    return {
      success = false,
      error = err,
    }
  end

  local result = M.execute_atuin_command { "delete", "--namespace", namespace, key }
  if not result.success then
    return {
      success = false,
      error = result.error,
    }
  end

  return {
    success = true,
    error = nil,
  }
end

return M

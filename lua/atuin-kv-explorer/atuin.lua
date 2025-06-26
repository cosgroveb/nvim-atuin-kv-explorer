-- Atuin CLI integration module

local M = {}

--- Parse namespace list output
---@param output string Raw output from atuin kv list --all-namespaces
---@return table List of unique namespace names
local function parse_namespace_list(output)
  if not output or type(output) ~= "string" then
    return {}
  end

  local namespace_set = {}
  for line in output:gmatch "[^\r\n]+" do
    local trimmed = line:match "^%s*(.-)%s*$"
    if trimmed and trimmed ~= "" then
      -- Extract namespace part (everything before first dot)
      local namespace = trimmed:match "^([^%.]+)"
      if namespace then
        namespace_set[namespace] = true
      end
    end
  end

  -- Convert set to sorted array
  local namespaces = {}
  for namespace in pairs(namespace_set) do
    table.insert(namespaces, namespace)
  end
  table.sort(namespaces)

  return namespaces
end

--- Parse key list output
---@param output string Raw output from atuin kv list --namespace <namespace>
---@return table List of key names
local function parse_key_list(output)
  if not output or type(output) ~= "string" then
    return {}
  end

  local keys = {}
  for line in output:gmatch "[^\r\n]+" do
    local trimmed = line:match "^%s*(.-)%s*$"
    if trimmed and trimmed ~= "" then
      table.insert(keys, trimmed)
    end
  end

  return keys
end

--- Parse key value output
---@param output string Raw output from atuin kv get
---@param namespace string Namespace name
---@param key string Key name
---@return table|nil Simple key-value table
local function parse_key_value(output, namespace, key)
  if not output or type(output) ~= "string" or not namespace or not key then
    return nil
  end

  -- Trim trailing newline added by vim.fn.system
  local value = output:gsub("\n$", "")

  return {
    namespace = namespace,
    key = key,
    value = value,
  }
end

--- Validate string parameter
local function validate_string_param(param, param_name)
  if not param or type(param) ~= "string" or param == "" then
    error(param_name .. " must be a non-empty string")
  end
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
  result.data = parse_namespace_list(result.data)
  return result
end

--- List keys in a namespace
---@param namespace string Namespace name
---@return table Result with key list
function M.list_keys(namespace)
  validate_string_param(namespace, "Namespace")
  local result = M.execute_atuin_command { "list", "--namespace", namespace }
  if not result.success then
    return result
  end
  result.data = parse_key_list(result.data)
  return result
end

--- Get value for a specific key
---@param namespace string Namespace name
---@param key string Key name
---@return table Result with key value
function M.get_value(namespace, key)
  validate_string_param(namespace, "Namespace")
  validate_string_param(key, "Key")
  local result = M.execute_atuin_command { "get", "--namespace", namespace, key }
  if not result.success then
    return result
  end
  result.data = parse_key_value(result.data, namespace, key)
  return result
end

--- Set value for a specific key
---@param namespace string Namespace name
---@param key string Key name
---@param value string Value content to save
---@return table Result with success status and error information
function M.set_value(namespace, key, value)
  validate_string_param(namespace, "Namespace")
  validate_string_param(key, "Key")
  if type(value) ~= "string" then
    error "Value must be a string"
  end
  local result = M.execute_atuin_command { "set", "--namespace", namespace, "--key", key, value }
  if result.success then
    result.data = { namespace = namespace, key = key, value = value }
  end
  return result
end

--- Delete a key
---@param namespace string Namespace name
---@param key string Key name
---@return table Result with success status and error information
function M.delete_value(namespace, key)
  validate_string_param(namespace, "Namespace")
  validate_string_param(key, "Key")
  return M.execute_atuin_command { "delete", "--namespace", namespace, key }
end

return M

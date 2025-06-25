-- Data parsing for atuin output

local M = {}

--- Parse namespace list output
---@param output string Raw output from atuin kv list --all-namespaces
---@return table List of unique namespace names
function M.parse_namespace_list(output)
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
function M.parse_key_list(output)
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
function M.parse_key_value(output, namespace, key)
  if not output or type(output) ~= "string" then
    return nil
  end

  if not namespace or type(namespace) ~= "string" then
    return nil
  end

  if not key or type(key) ~= "string" then
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

return M

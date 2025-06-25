-- Telescope extension for atuin-kv-explorer

local telescope = require "telescope"
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local atuin = require "atuin-kv-explorer.atuin"

-- Forward declarations
local pick_keys
local show_value_in_buffer

-- Namespace picker
local function pick_namespaces(opts)
  opts = opts or {}

  -- Get namespaces from atuin
  local result = atuin.list_namespaces()
  if not result.success then
    vim.notify("Failed to load namespaces: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  pickers
    .new(opts, {
      prompt_title = "Atuin KV Namespaces",
      finder = finders.new_table {
        results = result.data,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            -- Open key picker for selected namespace
            pick_keys { namespace = selection.value }
          end
        end)
        return true
      end,
    })
    :find()
end

-- Key picker for a specific namespace
pick_keys = function(opts)
  opts = opts or {}
  local namespace = opts.namespace

  if not namespace then
    vim.notify("No namespace specified", vim.log.levels.ERROR)
    return
  end

  -- Get keys from atuin
  local result = atuin.list_keys(namespace)
  if not result.success then
    vim.notify("Failed to load keys: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  pickers
    .new(opts, {
      prompt_title = "Keys in " .. namespace .. " (type new key name to create)",
      finder = finders.new_table {
        results = result.data,
      },
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer {
        title = "Value Preview",
        define_preview = function(self, entry, _status)
          local value_result = atuin.get_value(namespace, entry.value)
          if value_result.success and value_result.data then
            local lines = vim.split(value_result.data.value, "\n")
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          else
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Failed to load value" })
          end
        end,
      },
      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          local key_name

          if selection then
            -- Existing key selected
            key_name = selection.value
          else
            -- No selection, use what user typed as new key name
            local picker = action_state.get_current_picker(prompt_bufnr)
            key_name = picker:_get_prompt()

            if not key_name or key_name == "" then
              vim.notify("Please enter a key name", vim.log.levels.WARN)
              return
            end
          end

          actions.close(prompt_bufnr)
          show_value_in_buffer(namespace, key_name)
        end)
        return true
      end,
    })
    :find()
end

-- Show value in an editable buffer
show_value_in_buffer = function(namespace, key)
  local result = atuin.get_value(namespace, key)
  local initial_content = ""

  if result.success then
    -- Key exists, use its current value
    initial_content = result.data.value or ""
  else
    -- Key doesn't exist, create empty editable buffer for new key creation
    vim.notify(string.format("Key %s/%s does not exist, creating new key", namespace, key), vim.log.levels.INFO)
  end

  -- Create editable buffer
  local buffer = require "atuin-kv-explorer.buffer"
  local bufnr = buffer.create_editable_buffer(namespace, key, initial_content)

  -- Open in a new split
  vim.cmd "split"
  vim.api.nvim_win_set_buf(0, bufnr)
end

-- Combined search across all namespaces and keys
local function search_all(opts)
  opts = opts or {}

  -- Get all namespaces first
  local ns_result = atuin.list_namespaces()
  if not ns_result.success then
    vim.notify("Failed to load namespaces: " .. (ns_result.error or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Collect all namespace/key combinations
  local all_items = {}
  for _, namespace in ipairs(ns_result.namespaces or ns_result.data) do
    local key_result = atuin.list_keys(namespace)
    if key_result.success then
      for _, key in ipairs(key_result.data) do
        table.insert(all_items, {
          display = namespace .. " → " .. key,
          namespace = namespace,
          key = key,
        })
      end
    end
  end

  -- Allow empty results for manual input

  pickers
    .new(opts, {
      prompt_title = "Search All Atuin KV (format: namespace/key to create new)",
      finder = finders.new_table {
        results = all_items,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer {
        title = "Value Preview",
        define_preview = function(self, entry, _status)
          local item = entry.value
          local value_result = atuin.get_value(item.namespace, item.key)
          if value_result.success and value_result.data then
            local lines = vim.split(value_result.data.value, "\n")
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          else
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Failed to load value" })
          end
        end,
      },
      attach_mappings = function(prompt_bufnr, _map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()

          if selection then
            -- Existing key selected
            local item = selection.value
            actions.close(prompt_bufnr)
            show_value_in_buffer(item.namespace, item.key)
          else
            -- No selection, parse what user typed as namespace/key
            local picker = action_state.get_current_picker(prompt_bufnr)
            local input = picker:_get_prompt()

            if not input or input == "" then
              vim.notify("Please enter namespace/key format", vim.log.levels.WARN)
              return
            end

            -- Parse namespace/key format
            local namespace, key = input:match "^([^/]+)/(.+)$"
            if not namespace or not key then
              vim.notify("Format: namespace/key", vim.log.levels.WARN)
              return
            end

            actions.close(prompt_bufnr)
            show_value_in_buffer(namespace, key)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Setup function for telescope extension
local function setup(_opts)
  -- Extension setup configuration can go here
end

-- Register telescope extension
return telescope.register_extension {
  setup = setup,
  exports = {
    namespaces = pick_namespaces,
    keys = pick_keys,
    search = search_all,
  },
}

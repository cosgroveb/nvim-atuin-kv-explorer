-- Telescope extension for atuin-kv-explorer

local telescope = require "telescope"
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local atuin = require "atuin-kv-explorer.atuin"

-- Show value in an editable buffer
local function show_value_in_buffer(namespace, key)
  local result = atuin.get_value(namespace, key)
  local initial_content = result.success and result.data.value or ""

  if not result.success then
    vim.notify(string.format("Key %s/%s does not exist, creating new key", namespace, key), vim.log.levels.INFO)
  end

  local buffer = require "atuin-kv-explorer.buffer"
  local bufnr = buffer.create_editable_buffer(namespace, key, initial_content)
  -- switch to the buffer in current window
  vim.api.nvim_win_set_buf(0, bufnr)
end

-- Generic picker with delete functionality
local function create_picker(mode, opts)
  opts = opts or {}

  local items, prompt_title, preview_fn, select_fn

  if mode == "namespaces" then
    local result = atuin.list_namespaces()
    if not result.success then
      vim.notify("Failed to load namespaces: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
      return
    end
    items = result.data
    prompt_title = "Atuin KV Namespaces"
    select_fn = function(selection)
      if selection then
        create_picker("keys", { namespace = selection.value })
      end
    end
  elseif mode == "keys" then
    local namespace = opts.namespace
    if not namespace then
      vim.notify("No namespace specified", vim.log.levels.ERROR)
      return
    end

    local result = atuin.list_keys(namespace)
    if not result.success then
      vim.notify("Failed to load keys: " .. (result.error or "Unknown error"), vim.log.levels.ERROR)
      return
    end
    items = result.data
    prompt_title = "Keys in " .. namespace .. " (type new key name to create)"
    preview_fn = function(entry)
      local value_result = atuin.get_value(namespace, entry.value)
      return value_result.success and value_result.data and vim.split(value_result.data.value, "\n")
        or { "Failed to load value" }
    end
    select_fn = function(selection, typed_input)
      local key_name = selection and selection.value or typed_input
      if key_name and key_name ~= "" then
        show_value_in_buffer(namespace, key_name)
      else
        vim.notify("Please enter a key name", vim.log.levels.WARN)
      end
    end
  elseif mode == "search" then
    local ns_result = atuin.list_namespaces()
    if not ns_result.success then
      vim.notify("Failed to load namespaces: " .. (ns_result.error or "Unknown error"), vim.log.levels.ERROR)
      return
    end

    items = {}
    for _, namespace in ipairs(ns_result.data) do
      local key_result = atuin.list_keys(namespace)
      if key_result.success then
        for _, key in ipairs(key_result.data) do
          table.insert(items, {
            display = namespace .. " → " .. key,
            namespace = namespace,
            key = key,
          })
        end
      end
    end
    prompt_title = "Search All Atuin KV (format: namespace/key to create new)"
    preview_fn = function(entry)
      local item = entry.value
      local value_result = atuin.get_value(item.namespace, item.key)
      return value_result.success and value_result.data and vim.split(value_result.data.value, "\n")
        or { "Failed to load value" }
    end
    select_fn = function(selection, typed_input)
      if selection then
        local item = selection.value
        show_value_in_buffer(item.namespace, item.key)
      elseif typed_input and typed_input ~= "" then
        local namespace, key = typed_input:match "^([^/]+)/(.+)$"
        if namespace and key then
          show_value_in_buffer(namespace, key)
        else
          vim.notify("Format: namespace/key", vim.log.levels.WARN)
        end
      else
        vim.notify("Please enter namespace/key format", vim.log.levels.WARN)
      end
    end
  end

  local finder_opts = { results = items }
  if mode == "search" then
    finder_opts.entry_maker = function(entry)
      return {
        value = entry,
        display = entry.display,
        ordinal = entry.display,
      }
    end
  end

  local picker_opts = {
    prompt_title = prompt_title,
    finder = finders.new_table(finder_opts),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        local typed_input = not selection and action_state.get_current_picker(prompt_bufnr):_get_prompt()
        actions.close(prompt_bufnr)
        select_fn(selection, typed_input)
      end)

      if mode ~= "namespaces" then
        map("i", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if not selection then
            vim.notify("No key selected for deletion", vim.log.levels.WARN)
            return
          end

          local namespace, key
          if mode == "keys" then
            namespace, key = opts.namespace, selection.value
          else -- search mode
            local item = selection.value
            namespace, key = item.namespace, item.key
          end

          local confirm =
            vim.fn.confirm(string.format("Delete key '%s' from namespace '%s'?", key, namespace), "&Yes\n&No", 2)

          if confirm == 1 then
            local delete_result = atuin.delete_value(namespace, key)
            if delete_result.success then
              vim.notify(string.format("Deleted %s/%s", namespace, key))
              actions.close(prompt_bufnr)
              create_picker(mode, opts)
            else
              vim.notify(
                string.format("Failed to delete %s/%s: %s", namespace, key, delete_result.error),
                vim.log.levels.ERROR
              )
            end
          end
        end)
      end

      return true
    end,
  }

  if preview_fn then
    picker_opts.previewer = previewers.new_buffer_previewer {
      title = "Value Preview",
      define_preview = function(self, entry, _status)
        local lines = preview_fn(entry)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    }
  end

  pickers.new(opts, picker_opts):find()
end

-- Register telescope extension
return telescope.register_extension {
  setup = function(_opts) end,
  exports = {
    namespaces = function(opts)
      create_picker("namespaces", opts)
    end,
    keys = function(opts)
      create_picker("keys", opts)
    end,
    search = function(opts)
      create_picker("search", opts)
    end,
  },
}

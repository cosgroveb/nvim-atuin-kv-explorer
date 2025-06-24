-- atuin-kv-explorer.lua
-- Neovim plugin for exploring Atuin KV store data

-- Prevent double-loading
if vim.g.loaded_atuin_kv_explorer == 1 then
  return
end
vim.g.loaded_atuin_kv_explorer = 1

-- Plugin metadata
vim.g.atuin_kv_explorer_version = "0.1.0"

-- Register user commands
vim.api.nvim_create_user_command("AtuinKVExplorer", function()
  local explorer = require "atuin-kv-explorer.explorer"
  explorer.open()
end, { desc = "Open Atuin KV Explorer" })

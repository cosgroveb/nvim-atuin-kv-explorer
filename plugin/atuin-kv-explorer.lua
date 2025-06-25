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
  require("atuin-kv-explorer").open_explorer()
end, { desc = "Open Atuin KV Explorer (telescope or buffer mode)" })

vim.api.nvim_create_user_command("AtuinKVNamespaces", function()
  require("atuin-kv-explorer").telescope_namespaces()
end, { desc = "Browse Atuin KV namespaces with telescope" })

vim.api.nvim_create_user_command("AtuinKVSearch", function()
  require("atuin-kv-explorer").telescope_search()
end, { desc = "Search all Atuin KV keys with telescope" })

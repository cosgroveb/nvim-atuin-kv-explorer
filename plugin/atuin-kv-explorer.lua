-- atuin-kv-explorer.lua
-- Neovim plugin for exploring Atuin KV store data

-- Prevent double-loading
if vim.g.loaded_atuin_kv_explorer == 1 then
  return
end
vim.g.loaded_atuin_kv_explorer = 1

-- Plugin metadata
vim.g.atuin_kv_explorer_version = "0.1.0"

-- Command registration placeholder
-- Commands will be registered here after setup
# nvim-atuin-kv-explorer

A Neovim plugin for exploring Atuin KV store data with a telescope-style interface.

## Features

- **Telescope integration** - Familiar fuzzy search interface like your file picker
- **Preview support** - See value content as you browse keys
- **Namespace exploration** - Browse namespaces, then keys within them
- **Value editing** - Edit key values using standard Vim workflows (`:w` to save)
- **Key creation** - Create new keys by typing key names in telescope
- **Key deletion** - Delete keys with `<C-d>` and confirmation
- **Fallback UI** - Works with or without telescope installed

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "bcosgrove/nvim-atuin-kv-explorer",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- Optional but recommended
  },
  opts = {
    ui_mode = "auto", -- "auto", "telescope", or "buffer" (auto defaults to telescope if available)
  },
  cmd = { "AtuinKVExplorer", "AtuinKVNamespaces", "AtuinKVSearch" },
}
```

## Usage

### Commands

- `:AtuinKVExplorer` - Open the explorer (telescope or buffer mode)
- `:AtuinKVNamespaces` - Browse namespaces with telescope
- `:AtuinKVSearch` - Search across all namespace/key combinations

### Navigation

**Telescope mode** (default when available):
- Fuzzy search through namespaces and keys
- Preview window shows value content
- `<CR>` to select namespace or open key for editing
- `<C-d>` to delete selected key (with confirmation)
- Type new key names to create them
- `<Esc>` to close picker

**Buffer mode** (fallback):
- `<CR>` to select item
- `<BS>` to go back
- `q` to quit

**Value editing**:
- Edit values using standard Vim commands
- `:w` to save changes to atuin kv
- `:q` to close (warns about unsaved changes)
- Buffer name shows `atuin-kv://namespace/key`

## Configuration

```lua
require("atuin-kv-explorer").setup({
  ui_mode = "auto", -- "auto", "telescope", or "buffer" (auto prefers telescope)
  keymaps = {
    quit = "q",
    refresh = "r", 
    select = "<CR>",
    back = "<BS>",
  },
})
```

## Development

### Prerequisites

- Neovim 0.8+
- Atuin CLI installed and configured
- Rust/Cargo (for development tools)

### Setup

1. Clone the repository
2. Install development dependencies:
   ```bash
   make install-deps
   ```
   This installs stylua via cargo and prompts for luacheck installation.

### Development Workflow

Before committing, always run:
```bash
make check
```

This runs:
- `stylua` for code formatting
- `luacheck` for linting

Individual commands:
```bash
make format      # Check formatting
make format-fix  # Fix formatting
make lint        # Run linter
```

## Requirements

- Atuin CLI must be installed and available in PATH
- Neovim 0.8 or higher
- telescope.nvim (optional but recommended for best experience)

## Testing

Run the integration test suite:

```bash
make test
```

This tests all core functionality including telescope integration.
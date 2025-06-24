# nvim-atuin-kv-explorer

A Neovim plugin for exploring and managing Atuin KV store data directly from within Neovim.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/nvim-atuin-kv-explorer",
  opts = {
    -- Configuration options
  },
  cmd = { "AtuinKVExplorer" },
}
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
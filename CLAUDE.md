# nvim-atuin-kv-explorer Plugin Development

## Project Overview
A Neovim plugin in Lua that provides an interface for exploring and managing Atuin KV store data directly from within Neovim.

## Development Guidelines
- @~/.claude/docs/neovim-plugins.md - Comprehensive Neovim plugin development best practices
- Follow Lazy.nvim integration patterns for optimal user experience
- Use snake_case naming convention for Lua functions and variables
- Implement proper error handling with result-or-message patterns
- Keep the API simple and function-based (avoid complex OOP)

## Core Principles
- **SIMPLICITY FIRST**: We MUST ALWAYS implement the simplest, most obvious solution with as little indirection as possible
- **MINIMAL TESTING**: Our testing philosophy is complete end-to-end integration testing with as few tests as possible - perhaps just one test for each major feature
- **NO OVER-ENGINEERING**: Avoid abstractions, layers, or complex patterns unless absolutely necessary

## Plugin Structure
Following standard Neovim plugin conventions:
- `lua/atuin-kv-explorer/` - Main plugin modules
- `plugin/atuin-kv-explorer.lua` - Plugin initialization
- `doc/atuin-kv-explorer.txt` - Help documentation

## Key Features (Planned)  
- Browse Atuin KV namespaces and keys
- View/edit key-value pairs
- Integration with Neovim's native UI components
- Lazy loading for performance
- Comprehensive configuration options

## Development Requirements
- Always run `make check` before committing code
- Code must pass both stylua formatting and selene linting
- Use `make format-fix` to auto-fix formatting issues

## Linting Strategy
- **stylua**: Code formatting and style consistency
- **selene**: Lua linting and static analysis
- Both tools installed via cargo for consistency
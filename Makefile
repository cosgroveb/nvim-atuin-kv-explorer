.PHONY: lint format install-deps test clean

# Install development dependencies
install-deps:
	cargo install stylua
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing luacheck via Homebrew..."; \
		brew install luacheck; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "Installing luacheck via apt..."; \
		sudo apt-get update && sudo apt-get install -y lua-check; \
	else \
		echo "Please install luacheck manually for your system"; \
		echo "macOS: brew install luacheck"; \
		echo "Ubuntu/Debian: sudo apt-get install lua-check"; \
	fi

# Format code with stylua
format:
	stylua lua/ plugin/ --check

# Format code in place
format-fix:
	stylua lua/ plugin/

# Lint with luacheck
lint:
	luacheck lua/ plugin/ --config .luacheckrc

# Run all checks (format and lint)
check: format lint

# Run tests (placeholder for future)
test:
	@echo "Tests not implemented yet"

# Clean up generated files
clean:
	find . -name "*.tmp" -delete
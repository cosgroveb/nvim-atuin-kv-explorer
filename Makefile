.PHONY: lint format install-deps test clean

# Install development dependencies
install-deps:
	cargo install stylua

# Format code with stylua
format:
	stylua lua/ plugin/ --check

# Format code in place
format-fix:
	stylua lua/ plugin/

# Lint (using stylua for now)
lint: format

# Run all checks
check: format

# Run tests (placeholder for future)
test:
	@echo "Tests not implemented yet"

# Clean up generated files
clean:
	find . -name "*.tmp" -delete
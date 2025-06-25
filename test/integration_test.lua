-- Integration test for nvim-atuin-kv-explorer

-- Test namespace to avoid conflicts
local TEST_NAMESPACE = "nvim-plugin-test"
local TEST_KEY = "test-key"
local TEST_VALUE = "test value content\nwith multiple lines"

local function setup_test_data()
  -- Create test data in atuin
  local cmd = string.format("atuin kv set --namespace %s --key %s '%s'", TEST_NAMESPACE, TEST_KEY, TEST_VALUE)
  os.execute(cmd)
  print("Created test data: " .. TEST_NAMESPACE .. "/" .. TEST_KEY)
end

local function cleanup_test_data()
  -- Note: atuin doesn't have a delete command, so we leave test data
  print("Test completed - test data remains in atuin kv")
end

local function test_atuin_module()
  print("Testing atuin module...")
  
  local atuin = require "atuin-kv-explorer.atuin"
  
  -- Test namespace listing
  local ns_result = atuin.list_namespaces()
  assert(ns_result.success, "Failed to list namespaces: " .. (ns_result.error or "unknown"))
  assert(type(ns_result.data) == "table", "Namespace data should be a table")
  print("✓ Namespace listing works")
  
  -- Test key listing
  local key_result = atuin.list_keys(TEST_NAMESPACE)
  assert(key_result.success, "Failed to list keys: " .. (key_result.error or "unknown"))
  assert(type(key_result.data) == "table", "Key data should be a table")
  print("✓ Key listing works")
  
  -- Test value retrieval
  local val_result = atuin.get_value(TEST_NAMESPACE, TEST_KEY)
  assert(val_result.success, "Failed to get value: " .. (val_result.error or "unknown"))
  assert(type(val_result.data) == "table", "Value data should be a table")
  assert(val_result.data.value == TEST_VALUE, "Value content should match")
  print("✓ Value retrieval works")
end

local function test_buffer_module()
  print("Testing buffer module...")
  
  local buffer = require "atuin-kv-explorer.buffer"
  
  -- Create test buffer
  local bufnr = buffer.create_explorer_buffer()
  assert(bufnr > 0, "Buffer number should be positive")
  assert(vim.api.nvim_buf_is_valid(bufnr), "Buffer should be valid")
  print("✓ Buffer creation works")
  
  -- Test content display
  buffer.display(bufnr, "test content\nline 2")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  assert(#lines == 2, "Should have 2 lines")
  assert(lines[1] == "test content", "First line should match")
  assert(lines[2] == "line 2", "Second line should match")
  print("✓ Buffer display works")
  
  -- Clean up
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

local function test_list_view_module()
  print("Testing list_view module...")
  
  local list_view = require "atuin-kv-explorer.list_view"
  local buffer = require "atuin-kv-explorer.buffer"
  
  -- Create test buffer
  local bufnr = buffer.create_explorer_buffer()
  
  -- Test list display
  list_view.show_list(bufnr, {"item1", "item2", "item3"}, "No items")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  assert(#lines == 3, "Should have 3 lines")
  assert(lines[1] == "item1", "First item should match")
  print("✓ List display works")
  
  -- Test empty list
  list_view.show_list(bufnr, {}, "Empty list message")
  lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  assert(#lines == 1, "Should have 1 line for empty message")
  assert(lines[1] == "Empty list message", "Empty message should match")
  print("✓ Empty list handling works")
  
  -- Clean up
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

local function test_value_view_module()
  print("Testing value_view module...")
  
  local value_view = require "atuin-kv-explorer.value_view"
  
  -- Test value display (now creates its own editable buffer)
  value_view.show_value(nil, TEST_NAMESPACE, TEST_KEY)
  
  -- Check the current buffer (should be the editable buffer)
  local current_bufnr = vim.api.nvim_get_current_buf()
  local buffer_name = vim.api.nvim_buf_get_name(current_bufnr)
  local expected_name = string.format("atuin-kv://%s/%s", TEST_NAMESPACE, TEST_KEY)
  assert(buffer_name == expected_name, "Buffer name should match expected editable buffer name")
  
  -- Check buffer is modifiable
  local is_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = current_bufnr })
  assert(is_modifiable, "Value buffer should be editable")
  
  -- Check content matches
  local lines = vim.api.nvim_buf_get_lines(current_bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  assert(content == TEST_VALUE, "Displayed value should match test value")
  print("✓ Value display works with editable buffers")
  
  -- Clean up
  vim.api.nvim_buf_delete(current_bufnr, { force = true })
end

local function test_explorer_module()
  print("Testing explorer module (basic functionality)...")
  
  local explorer = require "atuin-kv-explorer.explorer"
  
  -- Test opening explorer (creates buffer and window)
  local initial_wins = #vim.api.nvim_list_wins()
  explorer.open()
  local new_wins = #vim.api.nvim_list_wins()
  assert(new_wins > initial_wins, "Should create new window")
  print("✓ Explorer opens successfully")
  
  -- Close the explorer window
  vim.cmd "close"
end

local function test_plugin_setup()
  print("Testing plugin setup and telescope integration...")
  
  -- Test basic setup
  local plugin = require "atuin-kv-explorer"
  plugin.setup()
  assert(plugin.is_setup(), "Plugin should be setup")
  print("✓ Plugin setup works")
  
  -- Test telescope extension loading (if telescope is available)
  local has_telescope = pcall(require, "telescope")
  if has_telescope then
    -- Check if extension was loaded
    local telescope = require "telescope"
    local extensions = telescope.extensions or {}
    assert(extensions.atuin_kv ~= nil, "Telescope extension should be loaded")
    print("✓ Telescope extension loaded")
  else
    print("✓ Telescope not available (skipping extension test)")
  end
end

-- Run all tests
local function run_tests()
  print("=== nvim-atuin-kv-explorer Integration Test ===")
  
  -- Setup
  setup_test_data()
  
  -- Run tests
  local tests = {
    test_atuin_module,
    test_buffer_module,
    test_list_view_module,
    test_value_view_module,
    test_explorer_module,
    test_plugin_setup,
  }
  
  local passed = 0
  local total = #tests
  
  for i, test_func in ipairs(tests) do
    local ok, err = pcall(test_func)
    if ok then
      passed = passed + 1
    else
      print("✗ Test failed: " .. err)
    end
  end
  
  -- Cleanup
  cleanup_test_data()
  
  -- Results
  print(string.format("\n=== Test Results: %d/%d passed ===", passed, total))
  
  if passed == total then
    print("All tests passed! 🎉")
    return true
  else
    print("Some tests failed! 😞")
    return false
  end
end

-- Auto-run if called directly
if vim.fn.argc() == 0 or vim.fn.argv()[1] == "test" then
  return run_tests()
else
  return { run_tests = run_tests }
end
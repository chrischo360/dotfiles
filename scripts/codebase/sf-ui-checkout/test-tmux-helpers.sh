#!/bin/bash

# test-tmux-helpers.sh - Unit tests for tmux-helpers.sh

set -euo pipefail

# Test configuration
readonly TEST_SESSION="test-dev-env"
readonly TEST_DIR="$HOME/codebase/sf-ui-checkout"

# Source the modules we're testing
source "lib/logging.sh"
source "lib/tmux-helpers.sh"

# Override TMUX_SESSION for testing
TMUX_SESSION="$TEST_SESSION"
SF_CHECKOUT_DIR="$TEST_DIR"

# Test results tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo ""
    echo "🧪 Running test: $test_name"
    echo "----------------------------------------"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if $test_function; then
        echo "✅ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✓ Assert passed: $message"
        return 0
    else
        echo "✗ Assert failed: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

assert_command_succeeds() {
    local command="$1"
    local message="${2:-}"
    
    if eval "$command" >/dev/null 2>&1; then
        echo "✓ Command succeeded: $message"
        return 0
    else
        echo "✗ Command failed: $message"
        echo "  Command: $command"
        return 1
    fi
}

assert_command_fails() {
    local command="$1"
    local message="${2:-}"
    
    if ! eval "$command" >/dev/null 2>&1; then
        echo "✓ Command failed as expected: $message"
        return 0
    else
        echo "✗ Command succeeded when it should have failed: $message"
        echo "  Command: $command"
        return 1
    fi
}

# Cleanup function
cleanup_test_session() {
    if tmux has-session -t "$TEST_SESSION" 2>/dev/null; then
        echo "🧹 Cleaning up test session..."
        tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
    fi
}

# Test 1: Basic tmux validation
test_tmux_validation() {
    validate_tmux
}

# Test 2: Session creation
test_session_creation() {
    # Ensure no existing session
    cleanup_test_session
    
    # Test session doesn't exist initially
    if session_exists; then
        echo "✗ Session should not exist initially"
        return 1
    fi
    
    # Create session
    if ! create_new_session; then
        echo "✗ Failed to create session"
        return 1
    fi
    
    # Test session exists after creation
    if ! session_exists; then
        echo "✗ Session should exist after creation"
        return 1
    fi
    
    echo "✓ Session creation successful"
    return 0
}

# Test 3: Pane creation verification
test_pane_creation() {
    # Ensure session exists
    if ! session_exists; then
        echo "✗ Session must exist for pane testing"
        return 1
    fi
    
    # Check pane count
    local pane_count=$(tmux list-panes -t "$TEST_SESSION" 2>/dev/null | wc -l)
    pane_count=$(echo "$pane_count" | tr -d ' ')  # Remove whitespace
    
    if ! assert_equals "6" "$pane_count" "Should have 6 panes"; then
        echo "Actual panes found:"
        tmux list-panes -t "$TEST_SESSION" -F "  Pane #{pane_index}: #{pane_current_command}"
        return 1
    fi
    
    echo "✓ Pane creation verification successful"
    return 0
}

# Test 4: Pane targeting format
test_pane_targeting() {
    if ! session_exists; then
        echo "✗ Session must exist for pane targeting testing"
        return 1
    fi
    
    # Test get_pane_target function
    local target=$(get_pane_target "4")
    if ! assert_equals "$TEST_SESSION:1.4" "$target" "Pane target format"; then
        return 1
    fi
    
    # Test actual pane targeting works
    local test_command="echo 'test-message-$$'"
    
    # Try to send command to pane 0 (should always exist)
    if ! tmux send-keys -t "$TEST_SESSION:1.0" "$test_command" Enter 2>/dev/null; then
        echo "✗ Failed to send command using session:window.pane format"
        return 1
    fi
    
    # Wait a moment and check if command was received
    sleep 1
    local pane_content=$(tmux capture-pane -t "$TEST_SESSION:1.0" -p 2>/dev/null)
    
    if echo "$pane_content" | grep -q "test-message-$$"; then
        echo "✓ Pane targeting successful"
        return 0
    else
        echo "✗ Command not found in pane content"
        echo "Pane content:"
        echo "$pane_content"
        return 1
    fi
}

# Test 5: Send command to pane function
test_send_command_to_pane() {
    if ! session_exists; then
        echo "✗ Session must exist for command sending testing"
        return 1
    fi
    
    local test_message="test-send-command-$$"
    
    # Test sending command to pane 0
    if ! send_command_to_pane "0" "echo '$test_message'"; then
        echo "✗ send_command_to_pane failed"
        return 1
    fi
    
    # Wait and verify
    sleep 1
    local pane_content=$(get_pane_content "0" 5)
    
    if echo "$pane_content" | grep -q "$test_message"; then
        echo "✓ send_command_to_pane successful"
        return 0
    else
        echo "✗ Command not found in pane content"
        echo "Pane content:"
        echo "$pane_content"
        return 1
    fi
}

# Test 6: Get pane content function
test_get_pane_content() {
    if ! session_exists; then
        echo "✗ Session must exist for pane content testing"
        return 1
    fi
    
    # Send a unique message
    local test_message="test-get-content-$$"
    tmux send-keys -t "$TEST_SESSION:1.0" "echo '$test_message'" Enter
    sleep 1
    
    # Test get_pane_content function
    local content=$(get_pane_content "0" 10)
    
    if echo "$content" | grep -q "$test_message"; then
        echo "✓ get_pane_content successful"
        return 0
    else
        echo "✗ Expected message not found in pane content"
        echo "Content:"
        echo "$content"
        return 1
    fi
}

# Test 7: Pane existence verification
test_pane_existence() {
    if ! session_exists; then
        echo "✗ Session must exist for pane existence testing"
        return 1
    fi
    
    # Test that panes 0-5 exist
    for pane in {0..5}; do
        if ! tmux list-panes -t "$TEST_SESSION:1.$pane" >/dev/null 2>&1; then
            echo "✗ Pane $pane does not exist"
            return 1
        fi
    done
    
    # Test that pane 6 doesn't exist
    if tmux list-panes -t "$TEST_SESSION:1.6" >/dev/null 2>&1; then
        echo "✗ Pane 6 should not exist"
        return 1
    fi
    
    echo "✓ Pane existence verification successful"
    return 0
}

# Test 8: Debug pane creation process
test_debug_pane_creation() {
    cleanup_test_session
    
    echo "🔍 Debugging pane creation step by step..."
    
    # Step 1: Create initial session
    echo "Step 1: Creating initial session..."
    tmux new-session -d -s "$TEST_SESSION" -c "$TEST_DIR"
    
    echo "After initial creation:"
    tmux list-panes -t "$TEST_SESSION" -F "  Pane #{pane_index}: #{pane_current_command}"
    
    # Step 2: First split (horizontal)
    echo "Step 2: First horizontal split..."
    if tmux split-window -h -t "$TEST_SESSION:1" -c "$TEST_DIR" 2>&1; then
        echo "✓ First split successful"
    else
        echo "✗ First split failed"
        return 1
    fi
    
    echo "After first split:"
    tmux list-panes -t "$TEST_SESSION" -F "  Pane #{pane_index}: #{pane_current_command}"
    
    # Step 3: Split left column
    echo "Step 3: Splitting left column..."
    if tmux split-window -v -t "$TEST_SESSION:1" -c "$TEST_DIR" 2>&1; then
        echo "✓ Left column first split successful"
    else
        echo "✗ Left column first split failed"
        return 1
    fi
    
    echo "After left column first split:"
    tmux list-panes -t "$TEST_SESSION" -F "  Pane #{pane_index}: #{pane_current_command}"
    
    return 0
}

# Main test runner
main() {
    echo "🧪 Starting tmux-helpers.sh Unit Tests"
    echo "======================================"
    
    # Cleanup any existing test session
    cleanup_test_session
    
    # Run tests
    run_test "Tmux Validation" test_tmux_validation
    run_test "Session Creation" test_session_creation
    run_test "Pane Creation Verification" test_pane_creation
    run_test "Pane Targeting Format" test_pane_targeting
    run_test "Send Command to Pane" test_send_command_to_pane
    run_test "Get Pane Content" test_get_pane_content
    run_test "Pane Existence Verification" test_pane_existence
    run_test "Debug Pane Creation Process" test_debug_pane_creation
    
    # Cleanup
    cleanup_test_session
    
    # Results
    echo ""
    echo "🏁 Test Results"
    echo "==============="
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 All tests passed!"
        return 0
    else
        echo "❌ Some tests failed!"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

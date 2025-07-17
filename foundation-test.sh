#!/bin/bash

# IMPORTANT: Code testing functionalities must be placed in ./foundation-tests/ 
# and be organized like database migration scripts. This ensures the foundation-test.sh
# script remains manageable and tests are modular.

# for each files that have been updated or newly created accoring to `git status`, git add file then commit
updated_tests=$(git status --porcelain | grep foundation | awk '{print $2}' | tr '\n' ' ')
if [ -n "$updated_tests" ] && [ "$updated_tests" != " " ]; then
    echo "Found updated foundation tests: $updated_tests"
    git add $updated_tests
    git commit -m "Update foundation tests $updated_tests"
fi

set -e

mkdir -p foundation-tests

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORKTREE_NAME="foundation-test-${TIMESTAMP}"
SESSION_NAME="foundation-test"

# Check if WIPE environment variable is set
if [ "$WIPE" = "true" ]; then
    echo "🗑️  WIPE=true detected - Database will be wiped on startup"
fi

# Import common utilities
source test-utils/common.sh

echo "🔍 Foundation Test Script"
echo "========================="
echo "Testing foundation layers to ensure solid base before development"
echo ""

# Parse command line arguments
FORCE_TESTS=false
QUIET_MODE=false
HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_TESTS=true
            shift
            ;;
        --quiet|-q)
            QUIET_MODE=true
            shift
            ;;
        --help|-h)
            HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            HELP=true
            shift
            ;;
    esac
done

if [ "$HELP" = true ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force    Force run all tests even if up-to-date"
    echo "  --quiet    Only show output when failures are detected"
    echo "  --help     Show this help message"
    echo ""
    echo "This script runs modular foundation tests from ./foundation-tests/"
    echo "Tests are organized like migration scripts for maintainability."
    exit 0
fi

# Source environment files
[ -f .env ] && source .env
[ -f .env.claude ] && source .env.claude

ROOT=$(pwd)

# Check if we're in main branch or already in a worktree
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || echo "")

# Check if we're already in a worktree by examining git directory structure
IN_WORKTREE=false
if [[ "$GIT_DIR" == *"worktrees"* ]] || [[ "$PWD" == *"worktrees/"* ]]; then
    IN_WORKTREE=true
fi

if [ "$CURRENT_BRANCH" = "main" ]; then
    if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
        echo "📁 Running tests in current directory (main branch, clean state)"
    else
        echo "📁 Running tests in current directory (main branch, with changes)"
        echo "   Foundation tests will validate current working state"
    fi
    TEST_DIR="$ROOT"
    USING_WORKTREE=false
elif [ "$IN_WORKTREE" = true ]; then
    echo "📁 Running tests in current worktree directory (branch: $CURRENT_BRANCH)"
    echo "   ⚠️  Testing current worktree state, not clean main branch"
    echo "   💡 For clean main branch testing, run from main directory"
    TEST_DIR="$ROOT"
    USING_WORKTREE=false
else
    echo "📁 Creating temporary worktree from main (currently on: $CURRENT_BRANCH)..."
    git worktree add "worktrees/${WORKTREE_NAME}" main || {
        echo "❌ Failed to create worktree"
        echo "   This usually happens when:"
        echo "   - Another worktree already exists"
        echo "   - Git repository issues"
        echo "   - Insufficient permissions"
        echo ""
        echo "💡 If you're already in a worktree, the test will run in place"
        echo "   To run from clean main: cd to main directory and run again"
        exit 1
    }
    TEST_DIR="$ROOT/worktrees/${WORKTREE_NAME}"
    USING_WORKTREE=true

    # Copy environment files if they exist (needed for database connections, etc.)
    if [ -f ".env" ]; then
        echo "📋 Copying .env file to worktree..."
        cp ".env" ${TEST_DIR}
    fi
    if [ -f ".env.claude" ]; then
        echo "📋 Copying .env.claude file to worktree..."
        cp ".env.claude" ${TEST_DIR}
    fi
    
    cd "$TEST_DIR" || {
        echo "❌ Failed to enter worktree"
        exit 1
    }
fi

# Set up test environment
export FORCE_TESTS
export QUIET_MODE
export ROOT
export TEST_DIR

# Source common utilities
if [ ! -f "test-utils/common.sh" ]; then
    echo "❌ Missing test-utils/common.sh - cannot run modular tests"
    echo "   Foundation tests require the common utilities file"
    exit 1
fi

source "test-utils/common.sh"

# Check requirements
if ! check_requirements; then
    exit 1
fi

# Initialize results and bug tracker files
init_results_file
init_bug_tracker

echo "🧪 Running modular foundation tests..."
echo ""

# Find foundation test scripts (001-099) and user story tests (100+) separately
FOUNDATION_TESTS=()
USER_STORY_TESTS=()
if [ -d "foundation-tests" ]; then
    while IFS= read -r -d '' script; do
        script_num=$(basename "$script" | cut -d'_' -f1)
        if [[ "$script_num" =~ ^0[0-9][0-9]$ ]]; then
            FOUNDATION_TESTS+=("$script")
        elif [[ "$script_num" =~ ^[1-9][0-9][0-9][0-9]$ ]]; then
            USER_STORY_TESTS+=("$script")
        fi
    done < <(find foundation-tests -name "*.sh" -type f -print0 | sort -z)
else
    echo "❌ Missing foundation-tests directory"
    echo "   Foundation tests must be modular and placed in ./foundation-tests/"
    exit 1
fi

if [ ${#FOUNDATION_TESTS[@]} -eq 0 ]; then
    echo "❌ No foundation test scripts found in foundation-tests/"
    echo "   Expected files like 001_project_structure.sh, 002_dependencies.sh, etc."
    exit 1
fi

echo "📋 Found ${#FOUNDATION_TESTS[@]} foundation test modules:"
for test_script in "${FOUNDATION_TESTS[@]}"; do
    echo "   - $(basename "$test_script")"
done
echo ""

# Run all foundation tests in order
TOTAL_TESTS=${#FOUNDATION_TESTS[@]}
PASSED_TESTS=0
FAILED_TESTS=0
BUGS_FOUND=0

for test_script in "${FOUNDATION_TESTS[@]}"; do
    test_name=$(basename "$test_script" .sh)
    echo "🔄 Running $test_script..."
    
    # Make script executable
    chmod +x "$test_script"
    
    # Start capturing output for this test script
    start_test_capture "$test_name"
    
    # Run the test script with full output capture
    TEST_OUTPUT=$(mktemp)
    if "$test_script" > "$TEST_OUTPUT" 2>&1; then
        # Test passed
        log_success "✅ $test_name completed successfully"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        finish_test_capture "true"
        
        # In quiet mode, don't show output for passing tests
        if [ "$QUIET_MODE" != true ]; then
            cat "$TEST_OUTPUT"
        fi
    else
        # Test failed - capture output and add to bug tracker
        log_error "❌ $test_name failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        # Read the captured output
        test_output_content=$(cat "$TEST_OUTPUT")
        
        # Add to test capture buffer and finish with failure
        TEST_OUTPUT_BUFFER="$test_output_content"
        finish_test_capture "false" "Foundation test script failed"
        
        # Always show output on failure (both quiet and normal mode)
        echo ""
        echo "📄 Test output for failed test:"
        echo "================================"
        echo "$test_output_content"
        echo "================================"
        
        # Count bugs found
        BUGS_FOUND=$((BUGS_FOUND + 1))
    fi
    rm -f "$TEST_OUTPUT"
    
    echo ""
done

# Generate final results
echo "## Final Foundation Status" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 **FOUNDATION IS SOLID** - All $TOTAL_TESTS tests PASSED" | tee -a "$RESULTS_FILE"
    echo "" >> "$BUG_TRACKER_FILE"
    echo "✅ **NO CRITICAL ISSUES FOUND** - Foundation is ready for development" >> "$BUG_TRACKER_FILE"
    FOUNDATION_STATUS="PASS"
    
    # Run user story tests if foundation passes
    if [ ${#USER_STORY_TESTS[@]} -gt 0 ]; then
        echo ""
        echo "🎭 Running User Story Tests..."
        echo "=============================="
        echo "Foundation passed - now testing complete user workflows"
        echo ""
        
        echo "📋 Found ${#USER_STORY_TESTS[@]} user story test modules:"
        for test_script in "${USER_STORY_TESTS[@]}"; do
            echo "   - $(basename "$test_script")"
        done
        echo ""
        
        # Run user story tests
        USER_STORY_PASSED=0
        USER_STORY_FAILED=0
        
        for test_script in "${USER_STORY_TESTS[@]}"; do
            test_name=$(basename "$test_script" .sh)
            echo "🎯 Running $test_script..."
            
            # Make script executable
            chmod +x "$test_script"
            
            # Start capturing output for this user story test script
            start_test_capture "$test_name"
            
            # Run the user story test with full output capture
            TEST_OUTPUT=$(mktemp)
            if "$test_script" > "$TEST_OUTPUT" 2>&1; then
                # Test passed
                log_success "✅ $test_name completed successfully"
                USER_STORY_PASSED=$((USER_STORY_PASSED + 1))
                finish_test_capture "true"
                
                # In quiet mode, don't show output for passing tests
                if [ "$QUIET_MODE" != true ]; then
                    cat "$TEST_OUTPUT"
                fi
            else
                # Test failed - capture output and add to bug tracker
                log_error "❌ $test_name failed"
                USER_STORY_FAILED=$((USER_STORY_FAILED + 1))
                
                # Read the captured output
                test_output_content=$(cat "$TEST_OUTPUT")
                
                # Add to test capture buffer and finish with failure
                TEST_OUTPUT_BUFFER="$test_output_content"
                finish_test_capture "false" "User story test script failed"
                
                # Always show output on failure (both quiet and normal mode)
                echo ""
                echo "📄 User Story test output for failed test:"
                echo "==========================================="
                echo "$test_output_content"
                echo "==========================================="
            fi
            rm -f "$TEST_OUTPUT"
            
            echo ""
        done
        
        # Update results with user story outcomes
        echo "" >> "$RESULTS_FILE"
        echo "## User Story Test Results" >> "$RESULTS_FILE"
        echo "" >> "$RESULTS_FILE"
        
        if [ $USER_STORY_FAILED -eq 0 ]; then
            echo "🎉 **ALL USER STORIES PASS** - Complete workflows working correctly" | tee -a "$RESULTS_FILE"
            echo "✅ **USER EXPERIENCE VALIDATED** - All user journeys from PROJECT.md work end-to-end" >> "$BUG_TRACKER_FILE"
        else
            echo "🚨 **USER STORY ISSUES** - $USER_STORY_FAILED of ${#USER_STORY_TESTS[@]} user stories FAILED" | tee -a "$RESULTS_FILE"
            echo "🚨 **USER EXPERIENCE BROKEN** - $USER_STORY_FAILED user workflows not working" >> "$BUG_TRACKER_FILE"
            FOUNDATION_STATUS="USER_STORY_FAIL"
        fi
        
        TOTAL_TESTS=$((TOTAL_TESTS + ${#USER_STORY_TESTS[@]}))
        PASSED_TESTS=$((PASSED_TESTS + USER_STORY_PASSED))
        FAILED_TESTS=$((FAILED_TESTS + USER_STORY_FAILED))
    fi
else
    echo "🚨 **FOUNDATION HAS ISSUES** - $FAILED_TESTS of $TOTAL_TESTS tests FAILED" | tee -a "$RESULTS_FILE"
    if [ $BUGS_FOUND -gt 0 ]; then
        echo "   Found $BUGS_FOUND critical issues that must be resolved" | tee -a "$RESULTS_FILE"
    fi
    echo "" >> "$BUG_TRACKER_FILE"
    echo "🚨 **FOUNDATION BLOCKED** - Found $FAILED_TESTS failed tests with critical issues" >> "$BUG_TRACKER_FILE"
    FOUNDATION_STATUS="FAIL"
fi

# Cleanup
echo "🧹 Cleaning up..."

# Stop any services that might have been started during testing - but only if we created a temporary worktree
# If we're running in an existing worktree, keep services running for development
if [ "$USING_WORKTREE" = true ] && [ -f "docker-compose.yml" ]; then
    echo "🗄️  Stopping database containers (temporary worktree)..."
    docker-compose down 2>/dev/null || true
elif [ "$IN_WORKTREE" = false ] && [ -f "docker-compose.yml" ]; then
    echo "🗄️  Stopping database containers (main branch)..."
    docker-compose down 2>/dev/null || true
else
    echo "ℹ️  Keeping database running (existing worktree development environment)"
fi

# Remove temporary worktree if we created one
if [ "$USING_WORKTREE" = true ]; then
    cd "$ROOT"
    echo "📁 Removing temporary worktree..."
    git worktree remove "worktrees/${WORKTREE_NAME}" --force 2>/dev/null || true
fi

# Final output
echo ""
echo "📋 Test Results:"
echo "   - Total tests: $TOTAL_TESTS"
echo "   - Passed: $PASSED_TESTS"
echo "   - Failed: $FAILED_TESTS"
echo "   - Critical issues: $BUGS_FOUND"
echo ""
echo "📄 Detailed results: ${RESULTS_FILE}"
echo "🐛 Issues tracker: ${BUG_TRACKER_FILE}"
echo ""

if [ "$FOUNDATION_STATUS" = "PASS" ]; then
    echo "✅ FOUNDATION TEST PASSED - Ready for development"
    exit 0
elif [ "$FOUNDATION_STATUS" = "USER_STORY_FAIL" ]; then
    echo "⚠️  FOUNDATION PASSED but USER STORIES FAILED"
    echo "   Technical foundation is solid but user workflows are broken"
    echo "   Fix user story issues in bug-tracker.md before considering complete"
    exit 1
else
    echo "❌ FOUNDATION TEST FAILED - Fix issues in bug-tracker.md first"
    exit 1
fi
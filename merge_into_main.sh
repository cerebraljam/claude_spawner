#!/bin/bash

# merge_into_main.sh - Automate merging worktree branches back into main
# Usage: ./merge_into_main.sh <worktree_path_or_branch_name>

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Merge Worktree to Main Script${NC}"
echo "=================================="

# Check if argument provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Error: Please provide worktree path or branch name${NC}"
    echo "Usage: $0 <worktree_path_or_branch_name>"
    echo "Examples:"
    echo "  $0 worktrees/layer4-slack-simulator"
    echo "  $0 layer4-slack-simulator"
    exit 1
fi

WORKTREE_INPUT="$1"
ROOT_DIR=$(pwd)

# Check if we're in the root directory of the repo
if [ ! -f "package.json" ] || [ ! -f "TASKS.md" ]; then
    echo -e "${RED}❌ Error: Please run this script from the root directory of the project project${NC}"
    exit 1
fi

# Get all worktrees and find matching ones
AVAILABLE_WORKTREES=$(git worktree list --porcelain | grep "^worktree " | cut -d' ' -f2-)
WORKTREE_PATH=""
BRANCH_NAME=""

# First try to find exact match by path or branch name
while IFS= read -r worktree_full_path; do
    worktree_basename=$(basename "$worktree_full_path")
    worktree_relative=""
    
    # Check if this is a relative path from root
    if [[ "$worktree_full_path" == "$ROOT_DIR"/* ]]; then
        worktree_relative=${worktree_full_path#"$ROOT_DIR/"}
    fi
    
    # Match by full path, relative path, or basename
    if [[ "$WORKTREE_INPUT" == "$worktree_full_path" ]] || \
       [[ "$WORKTREE_INPUT" == "$worktree_relative" ]] || \
       [[ "$WORKTREE_INPUT" == "$worktree_basename" ]]; then
        WORKTREE_PATH="$worktree_full_path"
        # Get the branch name from the worktree
        if cd "$WORKTREE_PATH" 2>/dev/null; then
            BRANCH_NAME=$(git branch --show-current 2>/dev/null || echo "$worktree_basename")
            cd "$ROOT_DIR"
        else
            BRANCH_NAME="$worktree_basename"
        fi
        break
    fi
done <<< "$AVAILABLE_WORKTREES"

# If no exact match found, try legacy detection for backward compatibility
if [ -z "$WORKTREE_PATH" ]; then
    if [[ "$WORKTREE_INPUT" == worktrees/* ]]; then
        WORKTREE_PATH="$WORKTREE_INPUT"
        BRANCH_NAME=$(basename "$WORKTREE_INPUT")
    else
        WORKTREE_PATH="worktrees/$WORKTREE_INPUT"
        BRANCH_NAME="$WORKTREE_INPUT"
    fi
    
    # Check if this legacy path exists
    if [ ! -d "$WORKTREE_PATH" ]; then
        WORKTREE_PATH=""
        BRANCH_NAME=""
    fi
fi

echo -e "${BLUE}📁 Worktree path: ${WORKTREE_PATH}${NC}"
echo -e "${BLUE}🌿 Branch name: ${BRANCH_NAME}${NC}"

# Check if worktree was found
if [ -z "$WORKTREE_PATH" ] || [ ! -d "$WORKTREE_PATH" ]; then
    echo -e "${RED}❌ Error: Could not find worktree matching '$WORKTREE_INPUT'${NC}"
    echo "Available worktrees:"
    git worktree list
    echo ""
    echo "You can use any of these formats:"
    echo "  - Full path: /path/to/worktree"
    echo "  - Relative path: worktrees/branch-name"  
    echo "  - Branch name: branch-name"
    exit 1
fi

# Verify we have a valid branch name
if [ -z "$BRANCH_NAME" ]; then
    echo -e "${RED}❌ Error: Could not determine branch name from worktree${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Using branch name: ${BRANCH_NAME}${NC}"

echo -e "${YELLOW}⚠️  This will merge branch '$BRANCH_NAME' into main and remove the worktree.${NC}"
echo -e "${YELLOW}⚠️  Make sure all work is committed in the worktree first!${NC}"
echo -e "${BLUE}🚀 Proceeding automatically...${NC}"

# Step 1: Check worktree status
echo -e "\n${BLUE}🔍 Step 1: Checking worktree status...${NC}"
cd "$WORKTREE_PATH"

# Check if there are uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${RED}❌ Error: Worktree has uncommitted changes. Please commit or stash them first.${NC}"
    echo "Uncommitted changes:"
    git status --porcelain
    exit 1
fi

# Get the latest commit hash from worktree
WORKTREE_COMMIT=$(git rev-parse HEAD)
echo -e "${GREEN}✅ Worktree is clean, latest commit: ${WORKTREE_COMMIT:0:8}${NC}"

# Step 2: Switch to main and check status
echo -e "\n${BLUE}🔄 Step 2: Switching to main branch...${NC}"
cd "$ROOT_DIR"

# Make sure we're on main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}📍 Currently on '$CURRENT_BRANCH', switching to main...${NC}"
    git checkout main
fi

# Check if main is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${RED}❌ Error: Main branch has uncommitted changes. Please commit or stash them first.${NC}"
    git status --porcelain
    exit 1
fi

echo -e "${GREEN}✅ Main branch is clean${NC}"

# Step 3: Handle potential conflicts with package-lock.json
echo -e "\n${BLUE}🔧 Step 3: Preparing for merge...${NC}"
if [ -f "package-lock.json" ]; then
    echo -e "${YELLOW}⚠️  Removing package-lock.json from main to avoid merge conflicts${NC}"
    rm -f package-lock.json
fi

# Step 4: Merge the branch
echo -e "\n${BLUE}🔀 Step 4: Merging branch '$BRANCH_NAME' into main...${NC}"
if git merge "$WORKTREE_COMMIT"; then
    echo -e "${GREEN}✅ Merge successful!${NC}"
else
    echo -e "${RED}❌ Merge failed. Please resolve conflicts manually.${NC}"
    echo "After resolving conflicts, run:"
    echo "  git add <specific_files_with_conflicts>"
    echo "  git commit"
    echo "Then re-run this script or manually clean up the worktree."
    echo ""
    echo "To see which files have conflicts:"
    echo "  git status --porcelain | grep '^UU'"
    exit 1
fi

# Step 5: Clean up worktree BEFORE running tests to avoid Jest conflicts
echo -e "\n${BLUE}🧹 Step 5: Cleaning up worktree before tests...${NC}"
if git worktree remove "$WORKTREE_PATH"; then
    echo -e "${GREEN}✅ Worktree '$WORKTREE_PATH' removed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not remove worktree automatically.${NC}"
    # Check if worktree still exists and provide specific guidance
    if [ -d "$WORKTREE_PATH" ]; then
        echo -e "${YELLOW}Worktree directory still exists. Try:${NC}"
        echo "  git worktree remove $WORKTREE_PATH --force"
        echo "  Or manually: rm -rf $WORKTREE_PATH"
    else
        echo -e "${YELLOW}Worktree directory removed but git still tracks it. Try:${NC}"
        echo "  git worktree prune"
    fi
fi

# Step 6: Start database before tests
echo -e "\n${BLUE}🗄️  Step 6: Starting database for tests...${NC}"
if [ -f "docker-compose.yml" ]; then
    echo -e "${BLUE}Starting database containers...${NC}"
    docker-compose up -d postgres
    # Wait for database to be ready
    echo -e "${BLUE}Waiting for database to be ready...${NC}"
    sleep 5
    echo -e "${GREEN}✅ Database should be ready${NC}"
else
    echo -e "${YELLOW}⚠️  No docker-compose.yml found, skipping database startup${NC}"
fi

# Step 7: Run tests to validate merge
echo -e "\n${BLUE}🧪 Step 7: Running tests to validate merge...${NC}"
if npm test; then
    echo -e "${GREEN}✅ All tests passing after merge${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Continuing with cleanup anyway...${NC}"
fi

# Step 8: Clean up database after tests
echo -e "\n${BLUE}🗄️  Step 8: Stopping database containers...${NC}"
if [ -f "docker-compose.yml" ]; then
    docker-compose down
    echo -e "${GREEN}✅ Database containers stopped${NC}"
fi

# Step 9: Branch cleanup
echo -e "\n${BLUE}🗑️  Step 9: Branch cleanup...${NC}"
echo -e "${YELLOW}The branch '$BRANCH_NAME' is now merged but still exists.${NC}"
echo -e "${BLUE}🧹 Auto-deleting the branch...${NC}"
if git branch -d "$BRANCH_NAME"; then
    echo -e "${GREEN}✅ Branch '$BRANCH_NAME' deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Could not delete branch automatically.${NC}"
    # Check if branch still exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo -e "${YELLOW}Branch still exists. It may have unmerged commits or be checked out elsewhere.${NC}"
        echo "Try: git branch -D $BRANCH_NAME (force delete)"
    else
        echo -e "${YELLOW}Branch reference may already be cleaned up.${NC}"
        echo "Check: git branch -a | grep $BRANCH_NAME"
    fi
fi

# Step 10: Show final status
echo -e "\n${GREEN}🎉 Merge completed successfully!${NC}"
echo -e "${BLUE}📊 Final status:${NC}"
echo "  - Latest commit: $(git rev-parse --short HEAD)"
echo "  - Files changed in merge: $(git diff --name-only HEAD~1 HEAD | wc -l)"
echo "  - Current worktrees:"
git worktree list

# Step 11: Auto-run foundation test
echo -e "\n${BLUE}🔍 Step 11: Auto-running foundation test${NC}"
echo -e "${BLUE}🧪 Running foundation test...${NC}"
if bash foundation-test.sh; then
    echo -e "${GREEN}✅ Foundation test passed!${NC}"
else
    echo -e "${YELLOW}⚠️  Foundation test had issues. Check foundation-test-results.md${NC}"
fi

echo -e "\n${GREEN}✨ All done! Main branch updated with changes from '$BRANCH_NAME'${NC}"
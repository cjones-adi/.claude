#!/bin/bash
# Run CI checks on CHANGED FILES ONLY
# Much faster than full repository scan

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

usage() {
    echo "Run CI checks on changed files only (fast)"
    echo ""
    echo "Usage: $0 [options] [base-branch]"
    echo ""
    echo "Options:"
    echo "  --since-rebase     Check only your changes since last rebase (recommended)"
    echo "  --help             Show this help"
    echo ""
    echo "Arguments:"
    echo "  base-branch        Compare against this branch (default: origin/main)"
    echo ""
    echo "Modes:"
    echo "  Default:           Shows ALL differences vs base branch"
    echo "                     (includes other people's changes pulled during rebase)"
    echo ""
    echo "  --since-rebase:    Shows only YOUR changes since branch divergence"
    echo "                     (excludes changes from main you pulled in)"
    echo ""
    echo "Examples:"
    echo "  $0                         # All changes vs origin/main"
    echo "  $0 --since-rebase          # Only YOUR changes (recommended)"
    echo "  $0 --since-rebase upstream/main"
    echo "  $0 HEAD~5                  # Last 5 commits"
}

# Parse arguments
SINCE_REBASE=false
BASE_BRANCH="origin/main"

while [[ $# -gt 0 ]]; do
    case $1 in
        --since-rebase)
            SINCE_REBASE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            echo_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            BASE_BRANCH="$1"
            shift
            ;;
    esac
done

# Verify we're in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo_error "Not in a git repository"
    exit 1
fi

echo ""
echo_info "🔍 CI Check - Changed Files Only"

# Determine comparison point
if [ "$SINCE_REBASE" = "true" ]; then
    # Find merge-base (common ancestor with base branch)
    MERGE_BASE=$(git merge-base "$BASE_BRANCH" HEAD 2>/dev/null || echo "")

    if [ -z "$MERGE_BASE" ]; then
        echo_error "Could not find merge-base with $BASE_BRANCH"
        echo_info "Make sure $BASE_BRANCH exists and you've fetched it"
        exit 1
    fi

    COMPARE_POINT="$MERGE_BASE"
    echo_info "Mode: Only YOUR changes since branch divergence"
    echo_info "Merge-base: $(git log --oneline -1 $MERGE_BASE)"
    echo_info "Your commits: $(git rev-list --count $MERGE_BASE..HEAD)"
else
    COMPARE_POINT="$BASE_BRANCH"
    echo_info "Mode: All differences vs $BASE_BRANCH"
    echo_info "Tip: Use --since-rebase to check only YOUR changes"
fi

echo ""

# Get changed files
get_changed_files() {
    git diff --name-only --diff-filter=d "$COMPARE_POINT"..HEAD | grep -E '\.(c|h)$' || true
}

CHANGED_FILES=$(get_changed_files)

if [ -z "$CHANGED_FILES" ]; then
    echo_warning "No C/C++ files changed"
    echo_success "Nothing to check - all clear!"
    exit 0
fi

# Count files
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
echo_info "Found $FILE_COUNT changed C/C++ file(s):"
echo "$CHANGED_FILES" | sed 's/^/  • /'
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: Code Formatting (AStyle)
echo_info "1️⃣  Checking code formatting on changed files..."

# Create temporary file list
TEMP_ASTYLE_FILES=$(mktemp)
echo "$CHANGED_FILES" > "$TEMP_ASTYLE_FILES"

# Run astyle on each file
ASTYLE_ISSUES=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Check if file should be ignored
        if [ -f ".astyleignore" ] && grep -qF "$file" .astyleignore 2>/dev/null; then
            continue
        fi

        # Run astyle
        if [ -f "build/astyle/build/gcc/bin/astyle" ]; then
            build/astyle/build/gcc/bin/astyle --options="ci/astyle_config" "$file" > /dev/null 2>&1
        elif command -v astyle > /dev/null 2>&1; then
            astyle --options="ci/astyle_config" "$file" > /dev/null 2>&1
        else
            echo_warning "AStyle not found - skipping format check"
            break
        fi
    fi
done < "$TEMP_ASTYLE_FILES"

rm -f "$TEMP_ASTYLE_FILES"

# Check if any files were modified
if git diff --exit-code > /dev/null 2>&1; then
    echo_success "Code formatting passed"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo_error "Code formatting issues found"
    echo_info "Files modified by AStyle:"
    git diff --name-only | sed 's/^/  • /'
    echo ""
    echo_info "Review changes: git diff"
    echo_info "Accept changes: git add -u"
    ASTYLE_ISSUES=1
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi
echo ""

# Check 2: Static Analysis (Cppcheck on changed files)
echo_info "2️⃣  Running static analysis on changed files..."
echo_info "Analyzing $FILE_COUNT file(s)..."

# Create array of files
mapfile -t FILES_ARRAY < <(echo "$CHANGED_FILES")

# Set parallel jobs
export NUM_JOBS=$(nproc)

# Build cppcheck args
CPPCHECK_ARGS=(
    "-j${NUM_JOBS}"
    "--quiet"
    "--force"
    "--error-exitcode=1"
    "--enable=warning,style,performance,portability"
    "--inconclusive"
    "-I./include"
    "-I./drivers"
)

# Add suppressions if file exists
if [ -f ".cppcheckignore" ]; then
    CPPCHECK_ARGS+=("--suppressions-list=.cppcheckignore")
fi

# Add library config if exists
if [ -f "./ci/config.cppcheck" ]; then
    CPPCHECK_ARGS+=("--library=./ci/config.cppcheck")
fi

# Run cppcheck on changed files
# Save output to temp file so we can show it and check exit code
CPPCHECK_OUTPUT=$(mktemp)
CPPCHECK_EXIT=0

echo_info "Running cppcheck..."
cppcheck "${CPPCHECK_ARGS[@]}" "${FILES_ARRAY[@]}" 2>&1 | tee "$CPPCHECK_OUTPUT" || CPPCHECK_EXIT=$?

echo ""

# Check results
if [ $CPPCHECK_EXIT -eq 0 ]; then
    # Check if any issues were reported (cppcheck outputs to stderr)
    if grep -q "error\|warning" "$CPPCHECK_OUTPUT" 2>/dev/null; then
        echo_warning "Cppcheck completed but found issues (see above)"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    else
        echo_success "Static analysis passed"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    fi
else
    echo_error "Static analysis found issues (see above)"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

rm -f "$CPPCHECK_OUTPUT"
echo ""

# Summary
echo "═══════════════════════════════════════════"
if [ $CHECKS_FAILED -eq 0 ]; then
    echo_success "🎉 All checks passed! ($FILE_COUNT file(s) analyzed)"
    echo ""
    echo_info "Changed files are clean:"
    echo "$CHANGED_FILES" | sed 's/^/  ✅ /'
    echo ""
    exit 0
else
    echo_error "❌ Some checks failed!"
    echo ""
    echo_info "Checks: $CHECKS_PASSED passed, $CHECKS_FAILED failed"
    echo ""
    if [ $ASTYLE_ISSUES -eq 1 ]; then
        echo_info "Fix formatting: Review 'git diff' and run 'git add -u' if acceptable"
    fi
    echo ""
    exit 1
fi

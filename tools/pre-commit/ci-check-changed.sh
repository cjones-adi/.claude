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
    echo "  --all-changes      Check ALL differences vs base branch"
    echo "                     (includes other people's changes pulled during rebase)"
    echo "  --help             Show this help"
    echo ""
    echo "Arguments:"
    echo "  base-branch        Compare against this branch (default: upstream/main)"
    echo ""
    echo "Modes:"
    echo "  Default:           Shows only YOUR changes since branch divergence"
    echo "                     (excludes changes from main you pulled in)"
    echo ""
    echo "  --all-changes:     Shows ALL differences vs base branch"
    echo "                     (includes all changes, even from rebase)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Only YOUR changes (default)"
    echo "  $0 --all-changes           # All differences vs upstream/main"
    echo "  $0 origin/main             # Only YOUR changes vs origin/main"
    echo "  $0 HEAD~5                  # Changes in last 5 commits"
}

# Parse arguments
SINCE_REBASE=true
BASE_BRANCH="upstream/main"

while [[ $# -gt 0 ]]; do
    case $1 in
        --all-changes)
            SINCE_REBASE=false
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
    echo_info "Mode: All differences vs $BASE_BRANCH (--all-changes)"
    echo_info "Tip: Remove --all-changes to check only YOUR changes since divergence"
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

# Run astyle on each file and track which files need formatting
# (using pre-commit hook's proven approach - test on temp copy, don't modify working copy)
ASTYLE_ISSUES=0
declare -a ASTYLE_MODIFIED_FILES=()

while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Check if file should be ignored
        if [ -f ".astyleignore" ] && grep -qF "$file" .astyleignore 2>/dev/null; then
            continue
        fi

        # Create a temporary copy to test formatting (don't modify working copy yet)
        cp "$file" "$file.tmp"

        # Run astyle on the TEMPORARY copy
        if [ -f "build/astyle/build/gcc/bin/astyle" ]; then
            build/astyle/build/gcc/bin/astyle --options="ci/astyle_config" "$file.tmp" > /dev/null 2>&1
        elif command -v astyle > /dev/null 2>&1; then
            astyle --options="ci/astyle_config" "$file.tmp" > /dev/null 2>&1
        else
            echo_warning "AStyle not found - skipping format check"
            rm -f "$file.tmp"
            break
        fi

        # Compare working copy with formatted temp copy
        # If different, working copy needs formatting
        if ! cmp -s "$file" "$file.tmp"; then
            ASTYLE_MODIFIED_FILES+=("$file")
            # Apply the formatting to the working copy
            cp "$file.tmp" "$file"
        fi

        rm -f "$file.tmp"
    fi
done < "$TEMP_ASTYLE_FILES"

rm -f "$TEMP_ASTYLE_FILES"

# Count modified files
MODIFIED_COUNT=${#ASTYLE_MODIFIED_FILES[@]}

if [ $MODIFIED_COUNT -eq 0 ]; then
    echo_success "Code formatting passed"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo_error "Code formatting issues found"
    echo_info "Files modified by AStyle (from your changed files only):"
    for file in "${ASTYLE_MODIFIED_FILES[@]}"; do
        echo "  • $file"
    done
    echo ""
    echo_warning "📋 How to Fix Formatting Issues:"
    echo ""
    echo "  ⚡ Quick Fix (run AStyle on all changed files):"
    echo "     git diff --name-only | grep -E '\.(c|h)\$' | xargs -I {} build/astyle/build/gcc/bin/astyle --options=ci/astyle_config {}"
    echo ""
    echo "  1️⃣  Review the changes:"
    echo "     git diff"
    echo ""
    echo "  2️⃣  Accept all formatting changes:"
    echo "     git add -u"
    echo ""
    echo "  3️⃣  Reject changes (restore original):"
    echo "     git checkout -- <file>"
    echo ""
    echo "  4️⃣  Suppress specific file from formatting:"
    echo "     echo \"path/to/file.c\" >> .astyleignore"
    echo ""
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

# Build cppcheck args (match pre-commit hook configuration)
CPPCHECK_ARGS=(
    "--force"
    "--error-exitcode=1"
    "--enable=warning,style,performance"
    "--template=gcc"
)

# Add suppressions if file exists
if [ -f ".cppcheckignore" ]; then
    CPPCHECK_ARGS+=("--suppressions-list=.cppcheckignore")
fi

# Add library config if exists
if [ -f "./ci/config.cppcheck" ]; then
    CPPCHECK_ARGS+=("--library=./ci/config.cppcheck")
fi

# Run cppcheck on changed files (using pre-commit hook's proven approach)
# Save output to temp file so we can show it and check exit code
CPPCHECK_OUTPUT=$(mktemp)
CPPCHECK_EXIT=0

echo_info "Running cppcheck..."
# Use xargs like pre-commit hook does
echo "$CHANGED_FILES" | xargs cppcheck ${CPPCHECK_ARGS[@]} 2>&1 | tee "$CPPCHECK_OUTPUT"
CPPCHECK_EXIT=${PIPESTATUS[1]}  # Get exit code of cppcheck (second command in pipe)

echo ""

# Check results
if [ $CPPCHECK_EXIT -eq 0 ]; then
    # Check if any issues were reported (cppcheck outputs to stderr)
    if grep -q "error\|warning" "$CPPCHECK_OUTPUT" 2>/dev/null; then
        echo_warning "Cppcheck completed but found issues (see above)"
        echo ""
        echo_warning "📋 How to Fix Static Analysis Issues:"
        echo ""
        echo "  1️⃣  Fix the code issues:"
        echo "     Review each warning/error and fix the actual code problem"
        echo ""
        echo "  2️⃣  For false positives, suppress in .cppcheckignore:"
        echo "     # Suppress specific error type"
        echo "     echo \"uninitvar\" >> .cppcheckignore"
        echo ""
        echo "     # Suppress for specific file"
        echo "     echo \"uninitvar:drivers/power/ltm4700/ltm4700.c\" >> .cppcheckignore"
        echo ""
        echo "  3️⃣  Re-run this check after fixes:"
        echo "     ./.claude/tools/pre-commit/ci-check-changed.sh"
        echo ""
        echo "  💡 Common Issues:"
        echo "     • uninitvar: Initialize variables before use"
        echo "     • nullPointer: Add NULL checks before dereferencing"
        echo "     • memleak: Ensure all allocated memory is freed"
        echo "     • unusedVariable: Remove unused variables or mark as (void)"
        echo ""
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    else
        echo_success "Static analysis passed"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    fi
else
    echo_error "Static analysis found issues (see above)"
    echo ""
    echo_warning "📋 How to Fix Static Analysis Issues:"
    echo ""
    echo "  1️⃣  Fix the code issues:"
    echo "     Review each warning/error and fix the actual code problem"
    echo ""
    echo "  2️⃣  For false positives, suppress in .cppcheckignore:"
    echo "     # Suppress specific error type"
    echo "     echo \"uninitvar\" >> .cppcheckignore"
    echo ""
    echo "     # Suppress for specific file"
    echo "     echo \"uninitvar:drivers/power/ltm4700/ltm4700.c\" >> .cppcheckignore"
    echo ""
    echo "  3️⃣  Re-run this check after fixes:"
    echo "     ./.claude/tools/pre-commit/ci-check-changed.sh"
    echo ""
    echo "  💡 Common Issues:"
    echo "     • uninitvar: Initialize variables before use"
    echo "     • nullPointer: Add NULL checks before dereferencing"
    echo "     • memleak: Ensure all allocated memory is freed"
    echo "     • unusedVariable: Remove unused variables or mark as (void)"
    echo ""
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
    echo_warning "🔧 Action Plan to Fix Issues:"
    echo ""

    # Priority 1: Fix formatting first (easiest)
    if [ $ASTYLE_ISSUES -eq 1 ]; then
        echo "  Priority 1: Fix Code Formatting"
        echo "  ────────────────────────────────"
        echo "  git diff                    # Review changes"
        echo "  git add -u                  # Accept formatting"
        echo ""
    fi

    # Priority 2: Fix static analysis
    if [ $CHECKS_FAILED -gt 0 ] && [ $ASTYLE_ISSUES -eq 0 ]; then
        echo "  Priority 1: Fix Static Analysis Issues"
        echo "  ───────────────────────────────────────"
        echo "  Review cppcheck warnings above and fix code issues"
        echo ""
    elif [ $CHECKS_FAILED -gt 1 ]; then
        echo "  Priority 2: Fix Static Analysis Issues"
        echo "  ───────────────────────────────────────"
        echo "  Review cppcheck warnings above and fix code issues"
        echo ""
    fi

    # Re-run instructions
    echo "  After Fixing:"
    echo "  ─────────────"
    echo "  ./.claude/tools/pre-commit/ci-check-changed.sh"
    echo ""
    echo "  📚 Additional Resources:"
    echo "  • Formatting guide: ./ci/astyle_config"
    echo "  • Suppression list: .cppcheckignore"
    echo "  • Cppcheck docs: https://cppcheck.sourceforge.io/"
    echo ""
    exit 1
fi

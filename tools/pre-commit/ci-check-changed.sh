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

# Get changed files by type
CHANGED_C_H_FILES=$(git diff --name-only --diff-filter=d "$COMPARE_POINT"..HEAD | grep -E '\.(c|h)$' || true)
CHANGED_RST_FILES=$(git diff --name-only --diff-filter=d "$COMPARE_POINT"..HEAD | grep -E '\.rst$' || true)

# For backward compatibility, keep CHANGED_FILES for C/H files
CHANGED_FILES="$CHANGED_C_H_FILES"

if [ -z "$CHANGED_C_H_FILES" ] && [ -z "$CHANGED_RST_FILES" ]; then
    echo_warning "No source or documentation files changed"
    echo_success "Nothing to check - all clear!"
    exit 0
fi

# Count files
C_H_COUNT=0
RST_COUNT=0
TOTAL_FILE_COUNT=0

if [ -n "$CHANGED_C_H_FILES" ]; then
    C_H_COUNT=$(echo "$CHANGED_C_H_FILES" | wc -l)
    TOTAL_FILE_COUNT=$((TOTAL_FILE_COUNT + C_H_COUNT))
fi

if [ -n "$CHANGED_RST_FILES" ]; then
    RST_COUNT=$(echo "$CHANGED_RST_FILES" | wc -l)
    TOTAL_FILE_COUNT=$((TOTAL_FILE_COUNT + RST_COUNT))
fi

# Keep FILE_COUNT for existing checks
FILE_COUNT=$C_H_COUNT

echo_info "Files to be checked:"
if [ -n "$CHANGED_C_H_FILES" ]; then
    echo -e "${BLUE}  📝 $C_H_COUNT C/H source file(s):${NC}"
    echo "$CHANGED_C_H_FILES" | sed 's/^/     • /'
fi
if [ -n "$CHANGED_RST_FILES" ]; then
    echo -e "${BLUE}  📚 $RST_COUNT documentation file(s):${NC}"
    echo "$CHANGED_RST_FILES" | sed 's/^/     • /'
fi
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

# Check 3: Documentation Completeness (Doxygen - Changed Files Only)
echo_info "3️⃣  Checking documentation completeness (Doxygen)..."

# Only check source files (already filtered in CHANGED_FILES)
if [ -z "$CHANGED_FILES" ]; then
    echo_success "No source files changed - skipping"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    # Check if doxygen is available
    if ! command -v doxygen > /dev/null 2>&1; then
        echo_warning "Doxygen not installed - skipping documentation check"
        echo_info "Install with: sudo apt-get install -y doxygen"
        echo ""
    else
        # Create temporary Doxyfile for changed files only
        TEMP_DOXYFILE=$(mktemp)
        TEMP_DOXY_OUT=$(mktemp -d)

        cat > "$TEMP_DOXYFILE" << 'DOXYEOF'
# Minimal Doxyfile for fast validation of changed files
PROJECT_NAME           = "Changed Files Validation"
OUTPUT_DIRECTORY       = TEMP_DOXY_OUT_PLACEHOLDER
GENERATE_HTML          = NO
GENERATE_LATEX         = NO
GENERATE_XML           = NO
WARNINGS               = YES
WARN_IF_UNDOCUMENTED   = YES
WARN_IF_DOC_ERROR      = YES
WARN_NO_PARAMDOC       = NO
WARN_FORMAT            = "$file:$line: $text"
QUIET                  = YES
RECURSIVE              = NO
DOXYEOF

        # Replace placeholder with actual temp directory
        sed -i "s|TEMP_DOXY_OUT_PLACEHOLDER|$TEMP_DOXY_OUT|g" "$TEMP_DOXYFILE"

        # Add INPUT files (changed files only)
        echo "INPUT = \\" >> "$TEMP_DOXYFILE"
        echo "$CHANGED_FILES" | while IFS= read -r file; do
            echo "    $(pwd)/$file \\" >> "$TEMP_DOXYFILE"
        done
        echo "" >> "$TEMP_DOXYFILE"

        echo_info "Analyzing $FILE_COUNT file(s) for documentation completeness..."

        # Run Doxygen on changed files only
        DOXY_OUTPUT=$(mktemp)
        doxygen "$TEMP_DOXYFILE" 2>&1 | tee "$DOXY_OUTPUT" > /dev/null
        DOXY_WARNINGS=$(grep -E "warning:|error:" "$DOXY_OUTPUT" || true)

        # Clean up temporary files
        rm -rf "$TEMP_DOXY_OUT" "$TEMP_DOXYFILE" "$DOXY_OUTPUT"

        if [ -z "$DOXY_WARNINGS" ]; then
            echo_success "Documentation completeness check passed"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            echo_error "Documentation issues found:"
            echo ""
            echo "$DOXY_WARNINGS"
            echo ""
            echo_warning "📋 How to Fix Documentation Issues:"
            echo ""
            echo "  Common issues:"
            echo "  • Missing @param for function parameters"
            echo "  • Missing @return for non-void functions"
            echo "  • Missing @brief for function description"
            echo "  • Undocumented public functions"
            echo "  • Parameter name mismatch between code and docs"
            echo ""
            echo "  Example fix:"
            echo "  /**"
            echo "   * @brief Initialize the device"
            echo "   * @param dev - Device descriptor"
            echo "   * @param init_param - Initialization parameters"
            echo "   * @return 0 in case of success, error code otherwise"
            echo "   */"
            echo ""
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
        fi
    fi
fi
echo ""

# Check 4: Sphinx RST Documentation (RST formatting)
if [ -n "$CHANGED_RST_FILES" ]; then
    echo_info "4️⃣  Checking RST documentation formatting (Sphinx)..."

    if ! command -v sphinx-build > /dev/null 2>&1; then
        echo_warning "Sphinx not installed - skipping RST validation"
        echo_info "Install with: pip3 install sphinx sphinx-rtd-theme breathe"
        echo ""
    else
        # Check if we're in the right directory structure
        if [ ! -d "doc/sphinx/source" ]; then
            echo_warning "Sphinx source directory not found - skipping"
            echo ""
        else
            echo_info "Analyzing $RST_COUNT RST file(s) for formatting issues..."

            # Run Sphinx build with -W (warnings as errors)
            # Note: Not using -Q (quiet) so we can see actual error details
            SPHINX_OUTPUT=$(mktemp)

            # Save current directory and change to sphinx source
            ORIGINAL_DIR=$(pwd)
            cd doc/sphinx/source

            # Run Sphinx with strict warnings (warnings become errors)
            # Filter to show only warnings/errors (not all build output)
            if make SPHINXOPTS="-W" html > "$SPHINX_OUTPUT" 2>&1; then
                SPHINX_RESULT=0
            else
                SPHINX_RESULT=1
            fi

            # Return to original directory
            cd "$ORIGINAL_DIR"

            # Check if the failure was due to missing dependencies
            if grep -q "Could not import extension\|No module named" "$SPHINX_OUTPUT" 2>/dev/null; then
                echo_warning "Sphinx dependencies missing - skipping full validation"
                echo_info "Missing Python packages detected. Install with:"
                echo_info "  pip3 install -r doc/sphinx/source/requirements.txt"
                echo ""
                rm -f "$SPHINX_OUTPUT"
            elif [ $SPHINX_RESULT -eq 0 ]; then
                echo_success "RST formatting validation passed"
                CHECKS_PASSED=$((CHECKS_PASSED + 1))
                rm -f "$SPHINX_OUTPUT"
            else
                echo_error "RST formatting issues found:"
                echo ""
                # Show only warnings and errors (filter out build noise)
                grep -E "WARNING:|ERROR:|warning:|error:" "$SPHINX_OUTPUT" || cat "$SPHINX_OUTPUT"
                echo ""
                echo_warning "📋 How to Fix RST Formatting Issues:"
                echo ""
                echo "  Common issues:"
                echo "  • Title underline length must match title exactly"
                echo "  • Use consistent underline characters (=, -, ~, ^)"
                echo "  • Check for proper indentation in code blocks"
                echo "  • Verify toctree entries exist"
                echo "  • Ensure blank lines around directives"
                echo ""
                echo "  Example fix for title underline:"
                echo "  LTM4700 Driver"
                echo "  =============="
                echo "  (14 characters in title = 14 equal signs)"
                echo ""
                rm -f "$SPHINX_OUTPUT"
                CHECKS_FAILED=$((CHECKS_FAILED + 1))
            fi
        fi
    fi
else
    echo_info "4️⃣  No RST files changed - skipping Sphinx check"
fi
echo ""

# Check 5: Quick Project Build Test
# Detect if any project files changed
CHANGED_PROJECT_FILES=$(git diff --name-only --diff-filter=d "$COMPARE_POINT"..HEAD | grep "^projects/" || true)

if [ -n "$CHANGED_PROJECT_FILES" ]; then
    echo_info "5️⃣  Running quick project build test..."

    # Extract unique project names from changed files
    CHANGED_PROJECTS=$(echo "$CHANGED_PROJECT_FILES" | cut -d'/' -f2 | sort -u)
    PROJECT_COUNT=$(echo "$CHANGED_PROJECTS" | wc -l)

    echo_info "Detected $PROJECT_COUNT changed project(s):"
    echo "$CHANGED_PROJECTS" | sed 's/^/     • projects\//'
    echo ""

    # Test build for each changed project
    BUILD_ERRORS=0
    for project in $CHANGED_PROJECTS; do
        PROJECT_DIR="projects/$project"

        if [ ! -f "$PROJECT_DIR/builds.json" ]; then
            echo_warning "No builds.json found for $project - skipping build test"
            continue
        fi

        # Extract ALL build configurations from builds.json
        BUILD_CONFIGS=$(python3 -c "
import json
import sys
try:
    with open('$PROJECT_DIR/builds.json', 'r') as f:
        builds = json.load(f)
    for platform, configs in builds.items():
        for build_name, build_config in configs.items():
            print(f'{platform}|{build_name}|{build_config[\"flags\"]}')
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1)

        if [ $? -ne 0 ]; then
            echo_error "Failed to parse builds.json for $project"
            BUILD_ERRORS=$((BUILD_ERRORS + 1))
            continue
        fi

        # Count build configurations
        BUILD_CONFIG_COUNT=$(echo "$BUILD_CONFIGS" | wc -l)
        echo_info "Found $BUILD_CONFIG_COUNT build configuration(s) for $project"
        echo ""

        # Test each build configuration
        CONFIG_NUM=0
        while IFS= read -r build_info; do
            CONFIG_NUM=$((CONFIG_NUM + 1))

            # Parse build info
            PLATFORM=$(echo "$build_info" | cut -d'|' -f1)
            BUILD_NAME=$(echo "$build_info" | cut -d'|' -f2)
            BUILD_FLAGS=$(echo "$build_info" | cut -d'|' -f3)

            echo_info "[$CONFIG_NUM/$BUILD_CONFIG_COUNT] Testing: $BUILD_NAME ($PLATFORM)"
            echo_info "Build flags: $BUILD_FLAGS"

            # Run the build
            BUILD_OUTPUT=$(mktemp)
            cd "$PROJECT_DIR"

            if make $BUILD_FLAGS > "$BUILD_OUTPUT" 2>&1; then
                echo_success "Build passed: $BUILD_NAME"
            else
                echo_error "Build failed: $BUILD_NAME"
                echo ""
                echo "Build errors:"
                tail -50 "$BUILD_OUTPUT" | grep -E "error:|Error:|fatal:|undefined reference" || tail -20 "$BUILD_OUTPUT"
                echo ""
                BUILD_ERRORS=$((BUILD_ERRORS + 1))
            fi

            # Clean up build artifacts
            make clean > /dev/null 2>&1 || true
            rm -f "$BUILD_OUTPUT"
            cd - > /dev/null
            echo ""
        done <<< "$BUILD_CONFIGS"
    done

    if [ $BUILD_ERRORS -eq 0 ]; then
        echo_success "All project builds passed"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo_error "$BUILD_ERRORS project build(s) failed"
        echo ""
        echo_warning "📋 How to Fix Build Issues:"
        echo ""
        echo "  Common issues:"
        echo "  • Missing #include directives"
        echo "  • Undefined references - check src.mk dependencies"
        echo "  • Syntax errors in C code"
        echo "  • Missing platform-specific headers"
        echo ""
        echo "  To test manually:"
        echo "  cd projects/$project"
        echo "  make $BUILD_FLAGS"
        echo ""
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
else
    echo_info "5️⃣  No project files changed - skipping build test"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════"
if [ $CHECKS_FAILED -eq 0 ]; then
    echo_success "🎉 All checks passed! ($TOTAL_FILE_COUNT file(s) analyzed)"
    echo ""
    echo_info "Changed files are clean:"
    if [ -n "$CHANGED_C_H_FILES" ]; then
        echo "$CHANGED_C_H_FILES" | sed 's/^/  ✅ /'
    fi
    if [ -n "$CHANGED_RST_FILES" ]; then
        echo "$CHANGED_RST_FILES" | sed 's/^/  ✅ /'
    fi
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

    # Priority 2: Fix static analysis and documentation
    PRIORITY=2
    if [ $ASTYLE_ISSUES -eq 0 ]; then
        PRIORITY=1
    fi

    echo "  Priority $PRIORITY: Fix Code Quality Issues"
    echo "  ────────────────────────────────────────"
    echo "  Review warnings above and fix:"
    echo "  • Cppcheck: static analysis issues"
    echo "  • Doxygen: missing/incomplete documentation"
    echo "  • Sphinx: RST formatting issues (title underlines, etc.)"
    echo "  • Build: compilation errors and missing dependencies"
    echo ""

    # Re-run instructions
    echo "  After Fixing:"
    echo "  ─────────────"
    echo "  ./.claude/tools/pre-commit/ci-check-changed.sh"
    echo ""
    echo "  📚 Additional Resources:"
    echo "  • Formatting guide: ./ci/astyle_config"
    echo "  • Suppression list: .cppcheckignore"
    echo "  • Cppcheck docs: https://cppcheck.sourceforge.io/"
    echo "  • Doxygen docs: https://www.doxygen.nl/manual/docblocks.html"
    echo "  • Sphinx/RST guide: https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html"
    echo ""
    exit 1
fi

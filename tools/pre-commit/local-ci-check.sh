#!/bin/bash
# Run CI checks locally before pushing to GitHub
# This runs the same checks that GitHub CI runs

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
    echo "Run CI checks locally"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --skip-format      Skip code formatting check (AStyle)"
    echo "  --skip-analysis    Skip static analysis check (Cppcheck)"
    echo "  --skip-build       Skip build validation (faster)"
    echo "  --quick            Skip both format and build (analysis only)"
    echo "  --full             Run all checks including build"
    echo "  --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run format + analysis (recommended)"
    echo "  $0 --quick         # Quick static analysis only"
    echo "  $0 --full          # All checks including build"
    echo "  $0 --skip-build    # Format + analysis (same as default)"
}

# Parse arguments
SKIP_FORMAT=0
SKIP_ANALYSIS=0
SKIP_BUILD=1  # Default: skip build (slow)

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-format)
            SKIP_FORMAT=1
            shift
            ;;
        --skip-analysis)
            SKIP_ANALYSIS=1
            shift
            ;;
        --skip-build)
            SKIP_BUILD=1
            shift
            ;;
        --quick)
            SKIP_FORMAT=1
            SKIP_BUILD=1
            shift
            ;;
        --full)
            SKIP_BUILD=0
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Set parallel jobs
export NUM_JOBS=$(nproc)

echo ""
echo_info "🔍 Running Local CI Validation"
echo_info "This runs the same checks as GitHub CI"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: Code Formatting (AStyle)
if [ $SKIP_FORMAT -eq 0 ]; then
    echo_info "1️⃣  Checking code formatting (AStyle)..."
    if ./ci/astyle.sh origin/main..HEAD 2>&1 | grep -q "Code style issues"; then
        echo_error "AStyle found formatting issues"
        echo_info "Review changes: git diff"
        echo_info "Accept changes: git add -u && git commit --amend --no-edit"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    else
        echo_success "Code formatting passed"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    fi
    echo ""
else
    echo_warning "Skipping code formatting check"
    echo ""
fi

# Check 2: Static Analysis (Cppcheck)
if [ $SKIP_ANALYSIS -eq 0 ]; then
    echo_info "2️⃣  Running static analysis (Cppcheck)..."
    echo_info "This may take 1-2 minutes..."

    # Run cppcheck and capture exit code (don't suppress output)
    CPPCHECK_EXIT=0
    ./ci/cppcheck.sh || CPPCHECK_EXIT=$?

    echo ""
    if [ $CPPCHECK_EXIT -eq 0 ]; then
        echo_success "Static analysis passed"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo_error "Static analysis found issues"
        echo_info "Review findings above and fix in source code"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
    echo ""
else
    echo_warning "Skipping static analysis check"
    echo ""
fi

# Check 3: Build Validation (Optional)
if [ $SKIP_BUILD -eq 0 ]; then
    echo_info "3️⃣  Building drivers..."
    echo_info "This may take 3-5 minutes..."
    if BUILD_TYPE=drivers ./ci/run_build.sh 2>&1; then
        echo_success "Build passed"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo_error "Build failed"
        echo_info "Review build errors above"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
    echo ""
else
    echo_warning "Skipping build validation (use --full to enable)"
    echo ""
fi

# Summary
echo "═══════════════════════════════════════════"
if [ $CHECKS_FAILED -eq 0 ]; then
    echo_success "🎉 All CI checks passed! ($CHECKS_PASSED/$CHECKS_PASSED)"
    echo ""
    echo_info "Your code is ready to push:"
    echo "  git push origin $(git branch --show-current)"
    echo ""
    exit 0
else
    echo_error "❌ Some checks failed! ($CHECKS_PASSED passed, $CHECKS_FAILED failed)"
    echo ""
    echo_info "Fix the issues above before pushing"
    echo ""
    exit 1
fi

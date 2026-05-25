# Running CI Checks Locally

**Purpose**: Validate your code before pushing to GitHub by running the same checks that CI runs.

---

## 🎯 Quick Start - Run All Checks

```bash
# 1. Code formatting (AStyle)
export NUM_JOBS=$(nproc)
./ci/astyle.sh origin/main..HEAD

# 2. Static analysis (Cppcheck) - Now stringent!
./ci/cppcheck.sh

# 3. Build validation (optional - requires toolchain)
export BUILD_TYPE=drivers
./ci/run_build.sh
```

**Time**: ~2-5 minutes total (depending on changes)

---

## 📋 Individual CI Checks

### 1. Code Formatting (AStyle)

**What it checks**: Code style compliance (indentation, braces, spacing)

```bash
# Set number of parallel jobs
export NUM_JOBS=$(nproc)

# Run AStyle on changed files vs main branch
./ci/astyle.sh origin/main..HEAD

# Or specify custom range
./ci/astyle.sh HEAD~5..HEAD  # Last 5 commits
```

**Output:**
- ✅ Success: No output, exit code 0
- ❌ Failure: "Code style issues found" + shows diffs

**Fix issues automatically:**
```bash
# AStyle will modify files in-place
./ci/astyle.sh origin/main..HEAD

# Review changes
git diff

# If acceptable, stage the changes
git add -u

# If not acceptable, restore
git restore .
```

---

### 2. Static Analysis (Cppcheck) - Updated Stringent Checks

**What it checks**:
- Memory leaks, null pointers, uninitialized variables
- Printf format mismatches, const correctness
- Portability issues (NEW)
- Inconclusive warnings (NEW)
- Symbol resolution with include paths (NEW)

```bash
# Set number of parallel jobs
export NUM_JOBS=$(nproc)

# Run stringent cppcheck (now matches local-static-analysis.sh)
./ci/cppcheck.sh
```

**What's analyzed:**
- Entire repository (drivers, include, util, iio, projects, etc.)
- All .c and .h files (except suppressions in `.cppcheckignore`)

**Output:**
- ✅ Success: No issues, exit code 0
- ❌ Failure: Lists issues, exit code 1

**Example failure:**
```
[drivers/power/ltm4700/ltm4700.c:123]: (warning) invalidPrintfArgType_sint:
  %d in format string requires 'int' but argument type is 'unsigned int'
```

**Fix workflow:**
```bash
# Run check
./ci/cppcheck.sh

# Fix reported issues in your editor
vim drivers/power/ltm4700/ltm4700.c

# Re-run to verify
./ci/cppcheck.sh
```

**Note**: CI cppcheck now includes:
- `--enable=warning,style,performance,portability` (portability is new)
- `--inconclusive` (catches more potential issues)
- `-I./include -I./drivers` (better symbol resolution)

---

### 3. Build Validation (Optional)

**What it checks**: Driver compilation for ARM embedded targets

**Prerequisites:**
```bash
# Install ARM toolchain (one-time)
sudo apt-get install -y gcc-arm-none-eabi libnewlib-arm-none-eabi
```

**Run build:**
```bash
export NUM_JOBS=$(nproc)
export BUILD_TYPE=drivers

./ci/run_build.sh
```

**What gets built:**
- All drivers in `drivers/` directory
- Uses ARM GCC cross-compiler
- Validates Makefile correctness

**Common failures:**
- Missing includes
- Undefined references
- Makefile syntax errors

---

### 4. Documentation Build (Optional)

**What it checks**: Sphinx/Doxygen documentation generation

**Prerequisites:**
```bash
# Install documentation tools (one-time, downloads ~100MB)
sudo apt-get install -y graphviz python3-pip
pip3 install -r doc/sphinx/source/requirements.txt
```

**Run documentation build:**
```bash
export NUM_JOBS=$(nproc)
export BUILD_TYPE=documentation

./ci/run_build.sh
```

**What gets generated:**
- Doxygen documentation from source code
- Sphinx documentation from .rst files
- Validates all documentation links and references

**Note**: This is the slowest check (~5-10 minutes first run)

---

## 🚀 Recommended Local Workflow

### Daily Development (Fast)

Use the enhanced local tools for quick feedback:

```bash
# 1. Quick local static analysis (30 seconds)
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# 2. Fix issues, then validate formatting
export NUM_JOBS=$(nproc)
./ci/astyle.sh origin/main..HEAD
```

**Why this is faster:**
- Local analysis only checks changed files
- AStyle only formats changed files
- Results available immediately

---

### Before Push (Comprehensive)

Run all CI checks to ensure GitHub CI will pass:

```bash
#!/bin/bash
# Save as: .claude/tools/pre-commit/local-ci-check.sh

set -e

echo "🔍 Running local CI validation..."
echo ""

# Set parallel jobs
export NUM_JOBS=$(nproc)

# 1. Code formatting
echo "1️⃣  Checking code formatting..."
./ci/astyle.sh origin/main..HEAD
echo "✅ AStyle passed"
echo ""

# 2. Static analysis
echo "2️⃣  Running static analysis..."
./ci/cppcheck.sh
echo "✅ Cppcheck passed"
echo ""

# 3. Optional: Build check
if [ "$SKIP_BUILD" != "1" ]; then
    echo "3️⃣  Building drivers..."
    export BUILD_TYPE=drivers
    ./ci/run_build.sh
    echo "✅ Build passed"
    echo ""
fi

echo "🎉 All CI checks passed! Safe to push."
```

**Usage:**
```bash
# Run all checks
./.claude/tools/pre-commit/local-ci-check.sh

# Skip build (faster)
SKIP_BUILD=1 ./.claude/tools/pre-commit/local-ci-check.sh
```

---

## 🔧 Troubleshooting

### AStyle Issues

**Problem**: "build/astyle not found"
```bash
# AStyle builds itself on first run
# Make sure you have internet connection and build tools
sudo apt-get install -y build-essential wget
```

**Problem**: "Code style issues found" but can't see what
```bash
# Run git diff to see changes AStyle made
git diff

# Review and commit if acceptable
git add -u
git commit -m "style: Apply AStyle formatting"
```

---

### Cppcheck Issues

**Problem**: "cppcheck: command not found"
```bash
# CI script auto-installs cppcheck 1.90
# Just run it once and it will download/install
./ci/cppcheck.sh
```

**Problem**: Too many warnings
```bash
# Add suppressions to .cppcheckignore
echo "**/libraries/*" >> .cppcheckignore
echo "**/build/*" >> .cppcheckignore
```

**Problem**: False positives
```bash
# Add specific suppression to .cppcheckignore
# Format: [error-id]:[file-pattern]
echo "unusedFunction:*/test_*.c" >> .cppcheckignore
```

---

### Build Issues

**Problem**: "gcc-arm-none-eabi: command not found"
```bash
# Install ARM toolchain
sudo apt-get update
sudo apt-get install -y gcc-arm-none-eabi libnewlib-arm-none-eabi
```

**Problem**: Build succeeds locally but fails in CI
```bash
# Ensure you're using the same toolchain version
arm-none-eabi-gcc --version

# CI uses specific versions - check .github/workflows/*.yml
```

---

## 📊 Comparison: Local Tools vs CI Scripts

| Check | Local Tool | CI Script | When to Use |
|-------|------------|-----------|-------------|
| **Static Analysis** | `.claude/tools/pre-commit/local-static-analysis.sh` | `ci/cppcheck.sh` | Local: Daily dev<br>CI: Pre-push |
| **Formatting** | `.claude/tools/pre-commit/*astyle*` (if exists) | `ci/astyle.sh` | CI: Always |
| **Build** | Manual: `make -C drivers` | `ci/run_build.sh` | CI: Pre-push |

**Key Difference:**
- **Local tools**: Optimized for speed (changed files only, HTML reports)
- **CI scripts**: Comprehensive (full repository, exit-code based)

**Best Practice:**
1. Use local tools during development (fast iteration)
2. Run CI scripts before push (catch CI failures early)

---

## 🎯 Integration with Pre-commit Hooks

Add CI validation to your pre-commit hook:

```bash
# Edit .git/hooks/pre-commit

#!/bin/bash

# Fast checks only (don't block commits)
export NUM_JOBS=$(nproc)

# Check formatting
if ! ./ci/astyle.sh HEAD~1..HEAD 2>/dev/null; then
    echo "⚠️  Warning: Code style issues detected"
    echo "   Fix with: ./ci/astyle.sh HEAD~1..HEAD"
    # Don't fail commit, just warn
fi

# Quick static analysis on changed files
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only
```

**Or use the install-hooks script:**
```bash
./.claude/tools/pre-commit/install-hooks.sh
# This sets up comprehensive pre-commit validation
```

---

## 💡 Pro Tips

### 1. Create Aliases

Add to `~/.bashrc`:
```bash
# Quick CI validation
alias ci-check='export NUM_JOBS=$(nproc) && ./ci/astyle.sh origin/main..HEAD && ./ci/cppcheck.sh'

# Full CI validation
alias ci-full='export NUM_JOBS=$(nproc) BUILD_TYPE=drivers && ./ci/astyle.sh origin/main..HEAD && ./ci/cppcheck.sh && ./ci/run_build.sh'
```

### 2. Check Before Push

Make it a habit:
```bash
# Before pushing
git status
ci-check
git push
```

### 3. Fix AStyle Automatically

AStyle modifies files in-place, so:
```bash
# Run AStyle
./ci/astyle.sh origin/main..HEAD

# Review changes
git diff

# If good, amend last commit
git add -u
git commit --amend --no-edit
```

### 4. Understand Exit Codes

```bash
# Exit code 0 = pass, non-zero = fail
./ci/cppcheck.sh && echo "PASS" || echo "FAIL"
```

### 5. Run in Parallel

```bash
# Run AStyle and Cppcheck in parallel (faster)
(./ci/astyle.sh origin/main..HEAD &)
(./ci/cppcheck.sh &)
wait
echo "Both completed"
```

---

## 🆘 Common Scenarios

### Scenario 1: "My PR failed CI but works locally"

**Check:**
```bash
# Ensure you're on latest main
git fetch origin
git merge origin/main

# Run exact CI checks
export NUM_JOBS=$(nproc)
./ci/astyle.sh origin/main..HEAD
./ci/cppcheck.sh

# If still passing locally, check:
# - .cppcheckignore differences
# - .astyleignore differences
# - Environment variables in CI
```

---

### Scenario 2: "I want to skip AStyle for generated files"

Add to `.astyleignore`:
```
**/generated/*
**/libraries/mbedtls/*
**/libraries/azure/*
```

Then run:
```bash
./ci/astyle.sh origin/main..HEAD
```

---

### Scenario 3: "Cppcheck is too slow"

The CI script analyzes the entire repository. For faster local development:

```bash
# Use local-static-analysis.sh instead (changed files only)
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open
```

Only run full CI cppcheck before pushing:
```bash
./ci/cppcheck.sh
```

---

## 📝 Summary

**Quick Reference:**

```bash
# Minimum before push
export NUM_JOBS=$(nproc)
./ci/astyle.sh origin/main..HEAD  # Format check
./ci/cppcheck.sh                  # Static analysis

# Comprehensive (includes build)
export BUILD_TYPE=drivers
./ci/run_build.sh                 # All CI checks
```

**Best Practice:**
1. **During development**: Use `.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open`
2. **Before push**: Run `./ci/astyle.sh` and `./ci/cppcheck.sh`
3. **Before PR**: Run full `BUILD_TYPE=drivers ./ci/run_build.sh`

This ensures you catch all issues locally before GitHub CI runs!

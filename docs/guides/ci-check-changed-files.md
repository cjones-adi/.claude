# CI Checks on Changed Files Only

**Problem**: CI scripts check the entire repository, which is slow when you only changed a few files.

**Solution**: Check only your changed files for much faster feedback.

---

## 🚀 Quick Start - Changed Files Only

```bash
# Check only YOUR changes since branch divergence (default)
./.claude/tools/pre-commit/ci-check-changed.sh

# Check vs different base branch
./.claude/tools/pre-commit/ci-check-changed.sh origin/main

# Check ALL differences (includes rebase changes)
./.claude/tools/pre-commit/ci-check-changed.sh --all-changes

# Check last N commits
./.claude/tools/pre-commit/ci-check-changed.sh HEAD~5
```

**Default behavior**: Uses `upstream/main` as base and shows only YOUR changes since branch divergence (excludes files pulled during rebase)

**Time**: ~10-30 seconds (vs 2-3 minutes for full repo)

---

## 📊 Comparison: Full Repo vs Changed Files

### Full Repository Check (Slow but Comprehensive)

```bash
# What CI does - checks EVERYTHING
export NUM_JOBS=$(nproc)
./ci/cppcheck.sh
```

**Characteristics:**
- ⏱️ Time: 2-3 minutes
- 📁 Files: Entire repository (~5000+ files)
- 🎯 Use: Before final push, comprehensive validation
- ✅ Finds issues anywhere in codebase

---

### Changed Files Only (Fast for Development)

```bash
# What you want during development - checks YOUR changes
./.claude/tools/pre-commit/ci-check-changed.sh
```

**Characteristics:**
- ⏱️ Time: 10-30 seconds
- 📁 Files: Only changed files (typically 5-20)
- 🎯 Use: During development, quick iteration
- ✅ Finds issues in your changes

---

## 🔍 What Gets Checked

### 1. Code Formatting (AStyle)

**Changed files only:**
```bash
# Automatically done by ci-check-changed.sh (uses merge-base by default)
# Or manually:
MERGE_BASE=$(git merge-base upstream/main HEAD)
git diff --name-only $MERGE_BASE..HEAD | grep -E '\.(c|h)$' | while read file; do
    astyle --options=ci/astyle_config "$file"
done
```

**What it does:**
- Checks indentation, braces, spacing
- Auto-fixes formatting issues
- Only touches files you changed

---

### 2. Static Analysis (Cppcheck)

**Changed files only:**
```bash
# Get your changed files (uses merge-base to exclude rebase changes)
MERGE_BASE=$(git merge-base upstream/main HEAD)
CHANGED_FILES=$(git diff --name-only $MERGE_BASE..HEAD | grep -E '\.(c|h)$')

# Run cppcheck only on those files
cppcheck \
    -j$(nproc) \
    --quiet \
    --force \
    --error-exitcode=1 \
    --enable=warning,style,performance,portability \
    --inconclusive \
    -I./include \
    -I./drivers \
    --suppressions-list=.cppcheckignore \
    --library=./ci/config.cppcheck \
    $CHANGED_FILES
```

**What it checks:**
- Memory leaks, null pointers
- Printf format mismatches
- Portability issues
- Const correctness
- **Only in your changed files**

---

## 💡 Example Workflow

### Scenario: Working on LTM4700 Driver

```bash
# Your changes
git status
# modified:   drivers/power/ltm4700/ltm4700.c
# modified:   drivers/power/ltm4700/ltm4700.h
# modified:   projects/ltm4700/src/examples/basic/basic_example.c

# Quick check on just these 3 files
./.claude/tools/pre-commit/ci-check-changed.sh
```

**Output:**
```
🔍 CI Check - Changed Files Only
Mode: Only YOUR changes since branch divergence
Merge-base: 61a204ed9 doc: Add Versal Variables N/A known issue to Vitis 2025 guide
Your commits: 8

Found 3 changed C/C++ file(s):
  • drivers/power/ltm4700/ltm4700.c
  • drivers/power/ltm4700/ltm4700.h
  • projects/ltm4700/src/examples/basic/basic_example.c

1️⃣  Checking code formatting on changed files...
✅ Code formatting passed

2️⃣  Running static analysis on changed files...
Analyzing 3 file(s)...
✅ Static analysis passed

═══════════════════════════════════════════
🎉 All checks passed! (3 file(s) analyzed)

Changed files are clean:
  ✅ drivers/power/ltm4700/ltm4700.c
  ✅ drivers/power/ltm4700/ltm4700.h
  ✅ projects/ltm4700/src/examples/basic/basic_example.c
```

**Time**: ~15 seconds (vs 2-3 minutes for full repo check)

---

## 🎯 Recommended Workflow

### During Development (Fast Iteration)

```bash
# 1. Make changes
vim drivers/power/ltm4700/ltm4700.c

# 2. Quick check - ONLY your changes
./.claude/tools/pre-commit/ci-check-changed.sh

# 3. Fix any issues

# 4. Commit
git add .
git commit -s -m "drivers: power: ltm4700: Fix issue"

# 5. Repeat steps 1-4 as needed
```

**Time per iteration**: ~15-30 seconds

---

### Before Push (Comprehensive)

```bash
# After all changes done, run full repo check
export NUM_JOBS=$(nproc)

# Full checks (what CI will run)
./ci/astyle.sh origin/main..HEAD
./ci/cppcheck.sh

# Or use the wrapper
./.claude/tools/pre-commit/local-ci-check.sh

# Push with confidence
git push
```

**Time**: ~2-3 minutes (but catches everything)

---

## 🔧 Manual Commands

### Check Specific Files

```bash
# Check just one file
cppcheck \
    --enable=warning,style,performance,portability \
    --inconclusive \
    -I./include \
    -I./drivers \
    drivers/power/ltm4700/ltm4700.c

# Check specific directory
cppcheck \
    --enable=warning,style,performance,portability \
    --inconclusive \
    -I./include \
    -I./drivers \
    drivers/power/ltm4700/

# Check project files only
cppcheck \
    --enable=warning,style,performance,portability \
    --inconclusive \
    -I./include \
    -I./drivers \
    projects/ltm4700/
```

---

### Check Changed Files in Different Ways

```bash
# Files changed vs origin/main
git diff --name-only origin/main...HEAD | grep -E '\.(c|h)$'

# Files changed vs upstream/main
git diff --name-only upstream/main...HEAD | grep -E '\.(c|h)$'

# Files changed in last 3 commits
git diff --name-only HEAD~3..HEAD | grep -E '\.(c|h)$'

# Staged files only
git diff --cached --name-only | grep -E '\.(c|h)$'

# Modified but not staged
git diff --name-only | grep -E '\.(c|h)$'
```

---

## 📋 Comparison Table

| Aspect | Full Repo Check | Changed Files Only |
|--------|----------------|-------------------|
| **Command** | `./ci/cppcheck.sh` | `./.claude/tools/pre-commit/ci-check-changed.sh` |
| **Time** | 2-3 minutes | 10-30 seconds |
| **Files** | ~5000+ files | Typically 5-20 files |
| **Coverage** | Entire codebase | Only your changes |
| **Best for** | Pre-push validation | Development iteration |
| **Catches** | Issues anywhere | Issues in your changes |

---

## 💡 Pro Tips

### 1. Create Alias for Quick Checks

Add to `~/.bashrc`:
```bash
# Quick check - changed files only
alias ci-quick='cd /home/cj/no-OS && ./.claude/tools/pre-commit/ci-check-changed.sh'

# Full check - entire repository
alias ci-full='cd /home/cj/no-OS && export NUM_JOBS=$(nproc) && ./ci/cppcheck.sh'
```

Usage:
```bash
ci-quick   # Fast - your changes only
ci-full    # Slow - comprehensive
```

---

### 2. Check Before Each Commit

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Fast check on changed files before commit

./.claude/tools/pre-commit/ci-check-changed.sh || {
    echo "Fix issues before committing"
    exit 1
}
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

### 3. Staged Files Only

Check only files you're about to commit:
```bash
# Get staged files
STAGED_FILES=$(git diff --cached --name-only | grep -E '\.(c|h)$')

# Check them
if [ -n "$STAGED_FILES" ]; then
    cppcheck \
        --enable=warning,style,performance,portability \
        --inconclusive \
        -I./include \
        -I./drivers \
        $STAGED_FILES
fi
```

---

### 4. Watch Mode (Continuous Checking)

For active development:
```bash
#!/bin/bash
# .claude/tools/pre-commit/watch-check.sh

while true; do
    clear
    echo "Watching for changes... (Ctrl+C to stop)"
    echo ""
    ./.claude/tools/pre-commit/ci-check-changed.sh
    sleep 10
done
```

Run in separate terminal:
```bash
./.claude/tools/pre-commit/watch-check.sh
```

---

## 🆘 Troubleshooting

### Issue: "No changed files found"

**Cause**: All your changes are committed
```bash
# Check status
git status

# See what's committed but not pushed
git log origin/main..HEAD --oneline
```

**Solution**: Either make changes or check committed files:
```bash
# Check last commit's files
git diff --name-only HEAD~1..HEAD | grep -E '\.(c|h)$'
```

---

### Issue: Script checks wrong base branch

**Cause**: Default is origin/main, but you use upstream/main
```bash
# Specify base explicitly
./.claude/tools/pre-commit/ci-check-changed.sh upstream/main
```

**Solution**: Create alias with your base:
```bash
alias ci-quick='./.claude/tools/pre-commit/ci-check-changed.sh upstream/main'
```

---

### Issue: AStyle not found

**Cause**: AStyle needs to be built first
```bash
# Build AStyle (one-time)
export NUM_JOBS=$(nproc)
./ci/astyle.sh origin/main..HEAD
# This will download and build AStyle
```

---

### Issue: Checks pass locally but fail in CI

**Cause**: Different files checked (you: changed only, CI: all)
```bash
# Run same check as CI
export NUM_JOBS=$(nproc)
./ci/cppcheck.sh
```

**Prevention**: Always run full check before pushing:
```bash
./.claude/tools/pre-commit/local-ci-check.sh
```

---

## 📊 Performance Comparison

### Real Example - LTM4700 Development

**Changed files:**
- 4 driver files (.c/.h)
- 6 project files (.c/.h)
- Total: 10 files, ~2000 lines

**Results:**

| Check Type | Files | Time | Use Case |
|-----------|-------|------|----------|
| **Changed files only** | 10 | 15 sec | ✅ Development iteration |
| **Full repository** | 5000+ | 180 sec | ⚠️ Before push only |
| **Local static analysis** | 10 | 30 sec | ✅ With HTML report |

**Conclusion**: For daily development, checking changed files only is **12x faster** and provides the same validation for your changes.

---

## 🎯 Summary

### Quick Commands

```bash
# During development (FAST - 15 sec)
./.claude/tools/pre-commit/ci-check-changed.sh

# Before push (THOROUGH - 3 min)
./.claude/tools/pre-commit/local-ci-check.sh

# Full CI check (what GitHub runs)
export NUM_JOBS=$(nproc)
./ci/cppcheck.sh
```

### Best Practice

1. **During development**: Use changed-files-only check for fast iteration
2. **Before commit**: Quick changed-files check
3. **Before push**: Full repository check to catch everything
4. **After CI failure**: Run full check locally to debug

This workflow gives you fast feedback during development while ensuring comprehensive validation before pushing to GitHub!

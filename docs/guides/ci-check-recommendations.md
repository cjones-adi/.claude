# CI Check Recommended Solutions

This document shows the enhanced recommendations provided by `ci-check-changed.sh` when issues are found.

---

## 📋 Formatting Issues (AStyle)

When AStyle finds formatting issues, you'll see:

```
❌ Code formatting issues found
Files modified by AStyle (from your changed files only):
  • drivers/power/ltm4700/ltm4700.c
  • drivers/power/ltm4700/ltm4700.h

📋 How to Fix Formatting Issues:

  ⚡ Quick Fix (run AStyle on all changed files):
     git diff --name-only | grep -E '\.(c|h)$' | xargs -I {} build/astyle/build/gcc/bin/astyle --options=ci/astyle_config {}

  1️⃣  Review the changes:
     git diff

  2️⃣  Accept all formatting changes:
     git add -u

  3️⃣  Reject changes (restore original):
     git checkout -- <file>

  4️⃣  Suppress specific file from formatting:
     echo "path/to/file.c" >> .astyleignore
```

### Quick Actions

**⚡ Quick Fix (one command to format all changed files):**
```bash
git diff --name-only | grep -E '\.(c|h)$' | xargs -I {} build/astyle/build/gcc/bin/astyle --options=ci/astyle_config {}
```

**Accept All Changes:**
```bash
git add -u
```

**Review Specific File:**
```bash
git diff drivers/power/ltm4700/ltm4700.c
```

**Reject All Changes:**
```bash
git checkout -- .
```

**Suppress File:**
```bash
echo "drivers/power/ltm4700/ltm4700.c" >> .astyleignore
```

---

## 🔍 Static Analysis Issues (Cppcheck)

When Cppcheck finds issues, you'll see:

```
❌ Static analysis found issues (see above)

📋 How to Fix Static Analysis Issues:

  1️⃣  Fix the code issues:
     Review each warning/error and fix the actual code problem

  2️⃣  For false positives, suppress in .cppcheckignore:
     # Suppress specific error type
     echo "uninitvar" >> .cppcheckignore

     # Suppress for specific file
     echo "uninitvar:drivers/power/ltm4700/ltm4700.c" >> .cppcheckignore

  3️⃣  Re-run this check after fixes:
     ./.claude/tools/pre-commit/ci-check-changed.sh

  💡 Common Issues:
     • uninitvar: Initialize variables before use
     • nullPointer: Add NULL checks before dereferencing
     • memleak: Ensure all allocated memory is freed
     • unusedVariable: Remove unused variables or mark as (void)
```

### Common Issues and Fixes

#### uninitvar (Uninitialized Variable)

**Error:**
```
drivers/power/ltm4700/ltm4700.c:45: error: Uninitialized variable: ret
```

**Fix:**
```c
// Before
int ret;
if (condition)
    ret = func();
return ret;  // ❌ ret uninitialized if condition is false

// After
int ret = 0;  // ✅ Initialize
if (condition)
    ret = func();
return ret;
```

#### nullPointer (Null Pointer Dereference)

**Error:**
```
drivers/power/ltm4700/ltm4700.c:78: error: Possible null pointer dereference: dev
```

**Fix:**
```c
// Before
int value = dev->data;  // ❌ dev might be NULL

// After
if (!dev)  // ✅ Check for NULL
    return -EINVAL;
int value = dev->data;
```

#### memleak (Memory Leak)

**Error:**
```
drivers/power/ltm4700/ltm4700.c:120: error: Memory leak: buffer
```

**Fix:**
```c
// Before
buffer = malloc(size);
if (error)
    return -ENOMEM;  // ❌ Leak: buffer not freed
process(buffer);
free(buffer);

// After
buffer = malloc(size);
if (error) {
    free(buffer);  // ✅ Free before return
    return -ENOMEM;
}
process(buffer);
free(buffer);
```

#### unusedVariable (Unused Variable)

**Error:**
```
drivers/power/ltm4700/ltm4700.c:95: warning: Unused variable: temp
```

**Fix:**
```c
// Option 1: Remove if truly unused
// int temp;  // ❌ Remove this

// Option 2: Mark as intentionally unused
int temp;
(void)temp;  // ✅ Suppress warning

// Option 3: Use the variable
int temp;
temp = read_temp();  // ✅ Actually use it
```

### Suppressing False Positives

**Suppress Specific Error Type:**
```bash
echo "uninitvar" >> .cppcheckignore
```

**Suppress Error for Specific File:**
```bash
echo "uninitvar:drivers/power/ltm4700/ltm4700.c" >> .cppcheckignore
```

**Suppress Specific Line:**
```c
// cppcheck-suppress uninitvar
int value = dev->data;
```

---

## 🔧 Action Plan Summary

When multiple checks fail, you'll see prioritized action plan:

```
❌ Some checks failed!

Checks: 0 passed, 2 failed

🔧 Action Plan to Fix Issues:

  Priority 1: Fix Code Formatting
  ────────────────────────────────
  git diff                    # Review changes
  git add -u                  # Accept formatting

  Priority 2: Fix Static Analysis Issues
  ───────────────────────────────────────
  Review cppcheck warnings above and fix code issues

  After Fixing:
  ─────────────
  ./.claude/tools/pre-commit/ci-check-changed.sh

  📚 Additional Resources:
  • Formatting guide: ./ci/astyle_config
  • Suppression list: .cppcheckignore
  • Cppcheck docs: https://cppcheck.sourceforge.io/
```

### Priority Order

1. **Fix Formatting First** (easiest, automatic)
   - Review: `git diff`
   - Accept: `git add -u`

2. **Fix Static Analysis** (requires code changes)
   - Review each warning
   - Fix actual code issues
   - Suppress false positives if needed

3. **Re-run Checks**
   ```bash
   ./.claude/tools/pre-commit/ci-check-changed.sh
   ```

---

## 🚀 Quick Reference

### Most Common Workflow

```bash
# 1. Run checks
./.claude/tools/pre-commit/ci-check-changed.sh

# 2. If formatting issues found
# Option A: Quick fix (one command)
git diff --name-only | grep -E '\.(c|h)$' | xargs -I {} build/astyle/build/gcc/bin/astyle --options=ci/astyle_config {}
git add -u         # Accept changes

# Option B: Review then accept
git diff           # Review
git add -u         # Accept

# 3. If cppcheck issues found
# Fix code issues in your editor

# 4. Re-run checks
./.claude/tools/pre-commit/ci-check-changed.sh

# 5. When all pass
git commit -s -m "drivers: power: ltm4700: Fix issue"
```

### Useful Commands

```bash
# ⚡ Quick fix - format all changed files with AStyle
git diff --name-only | grep -E '\.(c|h)$' | xargs -I {} build/astyle/build/gcc/bin/astyle --options=ci/astyle_config {}

# Review formatting changes
git diff

# Accept formatting changes
git add -u

# Reject formatting changes
git checkout -- .

# Suppress formatting for file
echo "path/to/file.c" >> .astyleignore

# Suppress cppcheck error type
echo "errorType" >> .cppcheckignore

# Suppress cppcheck for specific file
echo "errorType:path/to/file.c" >> .cppcheckignore

# Re-run checks
./.claude/tools/pre-commit/ci-check-changed.sh
```

---

## 📚 Additional Resources

- **AStyle Configuration**: `./ci/astyle_config`
- **Cppcheck Suppressions**: `.cppcheckignore`
- **Cppcheck Documentation**: https://cppcheck.sourceforge.io/
- **no-OS Coding Standards**: `CLAUDE.md`

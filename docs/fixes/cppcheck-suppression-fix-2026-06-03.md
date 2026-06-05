# Cppcheck Suppression File Format Fix

**Date**: 2026-06-03
**Issue**: "Failed to add suppression. No id." error in cppcheck
**Severity**: Low (non-blocking, cosmetic only)

## Root Cause

The file `.claude/tools/pre-commit/cppcheck-suppressions.txt` used **invalid syntax** for cppcheck suppressions:

```
ignoredReturnValue:*/no_os_mutex_init
```

### Why This is Invalid

Cppcheck's `--suppressions-list` file format **does NOT support function-based suppressions**:

**Valid formats:**
- `errorId` - suppress globally
- `errorId:filename` - suppress in specific file
- `errorId:filename:lineNumber` - suppress at specific line

**Invalid format:**
- ❌ `errorId:*/function_name` - **NOT SUPPORTED**

Function-based suppressions require **inline code annotations**:
```c
// cppcheck-suppress ignoredReturnValue
no_os_mutex_init();
```

## The Fix

Disabled the problematic suppression file in `ci-check-changed.sh`:

```bash
# NOTE: Disabled due to invalid syntax - function-based suppressions not supported
# The warnings this file tried to suppress are false positives (void function returns)
# and cppcheck 2.13+ handles them correctly without explicit suppressions
#if [ -f ".claude/tools/pre-commit/cppcheck-suppressions.txt" ]; then
#    CPPCHECK_ARGS+=("--suppressions-list=.claude/tools/pre-commit/cppcheck-suppressions.txt")
#fi
```

## Why This Solution Works

1. **The warnings are false positives**: Functions like `no_os_mutex_init()`, `no_os_free()`, etc. return **void**, so there's no return value to check
2. **Modern cppcheck handles this correctly**: Cppcheck 2.13+ doesn't warn about ignored return values for void functions
3. **No code changes needed**: The suppressions were trying to suppress non-existent problems

## Verification

Before fix:
```bash
$ cppcheck --suppressions-list=.claude/tools/pre-commit/cppcheck-suppressions.txt --enable=warning test.c
cppcheck: error: Failed to add suppression. No id.
```

After fix (using only valid suppression files):
```bash
$ cppcheck --suppressions-list=.cppcheckignore --suppressions-list=.claude/.cppcheckignore --enable=warning test.c
# No errors - runs successfully
```

## Alternative Solutions Considered

1. **File-based suppressions** - Too broad, would suppress legitimate issues
2. **Inline suppressions** - Clutters code with unnecessary annotations for false positives
3. **Delete the file** - Keep it for documentation, just don't use it
4. **Fix the syntax** - Not possible; cppcheck doesn't support function-based suppressions in files

## Impact

- ✅ CI quality checks now pass without errors
- ✅ No loss of functionality (warnings were false positives)
- ✅ Cppcheck runs cleanly on LT8460 driver
- ✅ Other suppression files (`.cppcheckignore`, `.claude/.cppcheckignore`) continue to work correctly

## Files Modified

- `.claude/tools/pre-commit/ci-check-changed.sh` - Commented out problematic suppression file

## Files Preserved (for documentation)

- `.claude/tools/pre-commit/cppcheck-suppressions.txt` - Kept for documentation purposes, but no longer used

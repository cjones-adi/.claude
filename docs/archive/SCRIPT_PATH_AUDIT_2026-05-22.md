# Script Path Audit Report
**Date**: 2026-05-22
**Issue**: Scripts reference old `tools/` paths instead of `.claude/tools/`
**Impact**: Scripts will fail to execute correctly after submodule migration
**Status**: 🔴 CRITICAL - Requires immediate fixes

---

## 🔍 Executive Summary

All 4 scripts contain hardcoded paths referencing the old `tools/` directory structure instead of the new `.claude/tools/` structure. This will cause:
- File not found errors
- Hook installation failures
- Template generation failures
- Validation check failures

---

## 📋 Detailed Findings

### 1. ❌ framework_validation.sh (.claude/tools/scripts/)

**Status**: MOSTLY OK (2 minor issues)

**Issues Found**:
- Line 212: References `docs/framework-validation-troubleshooting.md`
  - **Should be**: `.claude/docs/framework-validation-troubleshooting.md`
- Line 213: References `docs/framework-validation-lessons.md`
  - **Should be**: `.claude/docs/framework-validation-lessons.md`

**Working Correctly**:
- All repository-level path references (projects/, drivers/, tests/, include/, iio/)

**Impact**: LOW - Only affects help text at end of validation output

---

### 2. ❌ install-hooks.sh (.claude/tools/pre-commit/)

**Status**: BROKEN - Will fail to install hooks

**Issues Found**:
| Line | Current Path | Correct Path |
|------|-------------|--------------|
| 9 | `TOOLS_DIR="$REPO_ROOT/tools/pre-commit"` | `TOOLS_DIR="$REPO_ROOT/.claude/tools/pre-commit"` |
| 45 | `./tools/pre-commit/validate-setup.sh` | `./.claude/tools/pre-commit/validate-setup.sh` |

**Impact**: CRITICAL - Hook installation will completely fail

**Failures Expected**:
```bash
cp: cannot stat '/path/to/repo/tools/pre-commit/pre-commit': No such file or directory
cp: cannot stat '/path/to/repo/tools/pre-commit/commit-msg': No such file or directory
cp: cannot stat '/path/to/repo/tools/pre-commit/pre-commit-config.example': No such file or directory
```

---

### 3. ❌ validate-setup.sh (.claude/tools/pre-commit/)

**Status**: PARTIALLY BROKEN - Multiple validation checks will fail

**Issues Found**:
| Line | Current Path | Correct Path |
|------|-------------|--------------|
| 73 | `tools/pre-commit/pre-commit` | `.claude/tools/pre-commit/pre-commit` |
| 117 | `tools/pre-commit/check-branch-name.sh` | `.claude/tools/pre-commit/check-branch-name.sh` |
| 176 | `tools/pre-commit/check-branch-name.sh` | `.claude/tools/pre-commit/check-branch-name.sh` |
| 177 | `tools/pre-commit/create-device-template.py` | `.claude/tools/pre-commit/create-device-template.py` |
| 182 | `./tools/pre-commit/new-dev-branch.sh` | `./.claude/tools/pre-commit/new-dev-branch.sh` |
| 183 | `python3 tools/pre-commit/create-device-template.py` | `.claude/tools/pre-commit/create-device-template.py` |

**Impact**: HIGH - Validation will report incorrect status

**Failures Expected**:
- Pre-commit hook checks will falsely report "not found"
- Branch validation will fail
- Template generator checks will fail
- Quick start instructions will reference wrong paths

---

### 4. ❌ new-dev-branch.sh (.claude/tools/pre-commit/)

**Status**: PARTIALLY BROKEN - Recommendations will fail

**Issues Found**:
| Line | Current Path | Correct Path |
|------|-------------|--------------|
| 137 | `./tools/pre-commit/install-hooks.sh` | `./.claude/tools/pre-commit/install-hooks.sh` |
| 138 | `python3 tools/pre-commit/create-device-template.py` | `.claude/tools/pre-commit/create-device-template.py` |

**Impact**: MEDIUM - Script creates branch correctly, but next-steps instructions are wrong

**Failures Expected**:
- Recommended commands will fail when user copies and runs them
- User confusion due to incorrect paths in output

---

## 🔧 Required Fixes Summary

### Critical Fixes (Immediate):
1. **install-hooks.sh**: Update `TOOLS_DIR` path (line 9) and validate-setup reference (line 45)
2. **validate-setup.sh**: Update 6 path references across file
3. **new-dev-branch.sh**: Update 2 next-step recommendation paths

### Minor Fixes (Low Priority):
4. **framework_validation.sh**: Update 2 documentation path references in help text

---

## ✅ Proposed Solution

### Option 1: Systematic Update (Recommended)
Update all 4 scripts to use `.claude/tools/` paths:

**Advantages**:
- Aligns with new folder structure
- Prevents future confusion
- Maintains consistency across all files

**Effort**: ~10 minutes (simple find-replace operation)

### Option 2: Create Compatibility Symlinks
Create symlink at repository root:
```bash
ln -s .claude/tools tools
```

**Advantages**:
- Quick fix without code changes
- Backwards compatibility

**Disadvantages**:
- Perpetuates confusion about actual file locations
- Not a clean solution

**Recommendation**: Use Option 1 (systematic update)

---

## 📝 Testing Checklist

After fixes are applied, test each script:

- [ ] `framework_validation.sh ltm4700 power maxim` - Verify help text shows correct paths
- [ ] `install-hooks.sh` - Verify hooks install successfully
- [ ] `validate-setup.sh` - Verify all checks pass and show correct paths
- [ ] `new-dev-branch.sh test-device` - Verify recommendations show correct paths

---

## 🎯 Recommended Action

**Immediate Action Required**: Update all 4 scripts to reference `.claude/tools/` instead of `tools/`

**Priority Order**:
1. install-hooks.sh (CRITICAL - completely broken)
2. validate-setup.sh (HIGH - misleading validation results)
3. new-dev-branch.sh (MEDIUM - wrong recommendations)
4. framework_validation.sh (LOW - only help text affected)

---

**Next Steps**: Would you like me to update all 4 scripts with the correct paths?

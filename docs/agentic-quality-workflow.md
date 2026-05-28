# Agentic Quality Check Workflow

## Quick Start

### For Developers

Simply ask Claude to check code quality at any point:

```
"Check code quality"
"Run quality checks"
"Fix code issues"
"/quality-check"
```

### What Happens Automatically

Claude will:
1. ✅ Run `.claude/tools/pre-commit/ci-check-changed.sh` on changed files
2. ✅ Parse and categorize all findings
3. ✅ Offer to auto-fix simple issues (with your approval)
4. ✅ Present complex issues for your review
5. ✅ Verify builds and tests still pass
6. ✅ Stage changes (you commit manually)

## Example Workflow

### Scenario: After Implementing a Feature

```
You: I just finished adding the LTM4700 driver. Check code quality.

Claude: Running quality checks on changed files...

📊 Quality Check Results:
✅ Build: All builds passed
✅ Unit Tests: 245 tests passed, 94.2% coverage
⚠️  Code Quality: 11 issues found

Issue Breakdown:
  📋 Code Style: 7 issues (auto-fixable)
    - Redundant comments that restate function names
    - Redundant comments before if statements

  📋 Magic Numbers: 4 issues (need review)
    - 0x7FF needs semantic name
    - 400000 delay needs constant name

Would you like me to:
1. Auto-fix all 7 Code Style issues
2. Show Magic Number issues for review
3. Show all issues without fixing

You: 1

Claude: Fixing code style issues...
✅ Removed 7 redundant comments
✅ All formatting preserved
✅ Build still passes
✅ Tests still pass (245/245)

Changes staged. Run 'git diff' to review.

Remaining: 4 magic numbers need semantic names.
Would you like me to show those for review?

You: Yes

Claude: Here are the 4 magic numbers that need semantic names:

1. ltm4700.c:198 - 0x7FF
   Context: return (uint16_t)((exponent << 11) | (mantissa & 0x7FF));
   Suggestion: #define LTM4700_LIN11_MANTISSA_MASK 0x7FF

2. common_data.c:49 - 400000
   Context: .i2c_speed = 400000
   Suggestion: #define I2C_FAST_MODE_HZ 400000

...

Would you like me to fix any of these?

You: Fix 1 and 2

Claude: Applying fixes...
✅ Added #define LTM4700_LIN11_MANTISSA_MASK 0x7FF
✅ Updated usage in ltm4700.c:198
✅ Added #define I2C_FAST_MODE_HZ 400000
✅ Updated common_data.c:49

All quality checks now pass! ✅
```

## Auto-Fix Capabilities

### Always Safe to Auto-Fix (with approval)
- ✅ **Redundant comments** - Removes comments that just restate code
- ✅ **AStyle formatting** - Applies project code style
- ✅ **Simple refactoring** - Well-defined pattern replacements

### Requires Manual Review
- ❌ **Magic numbers** - Need semantic constant names (context-dependent)
- ❌ **API changes** - Could affect callers
- ❌ **Logic changes** - Could introduce bugs
- ❌ **Architecture** - Need design discussion

## When Claude Uses This Proactively

Claude will **automatically** run quality checks:

1. **After Phase 2 (Implementation)** - Before committing each of the 6 commits
2. **After user makes changes** - When files are modified
3. **Before creating PR** - Final quality verification
4. **When user asks "ready to commit?"** - Pre-commit validation

## Triggering Manually

### Direct Command
```bash
# User can run directly
./.claude/tools/pre-commit/ci-check-changed.sh
```

### Ask Claude
```
"Check code quality"
"Run quality checks"
"Fix code issues"
"Clean up the code"
"/quality-check"
```

### In Conversation
```
You: I think I'm done with the driver

Claude: Great! Let me run quality checks to make sure everything is clean...
[Runs checks automatically]
```

## Quality Check Scope

### What's Checked
- ✅ **Code formatting** (AStyle)
- ✅ **Static analysis** (Cppcheck)
- ✅ **Review patterns** (6-month PR analysis)
- ✅ **Documentation** (Doxygen)
- ✅ **Build verification** (Multi-platform)
- ✅ **Unit tests** (Ceedling, 80%+ coverage)
- ✅ **RST documentation** (Sphinx)

### What's NOT Checked
- ❌ Hardware testing (requires real hardware)
- ❌ Integration testing (requires full system)
- ❌ Performance profiling (requires benchmarking)
- ❌ SonarCloud (requires separate run)

## Benefits

### For Developers
- 🎯 **Catch issues early** - Before PR review
- ⚡ **Fast feedback** - Immediate results
- 🤖 **Automated fixes** - Save time on trivial issues
- 📚 **Learn patterns** - Understand code quality expectations

### For Code Quality
- ✅ **Consistent standards** - Automated enforcement
- 📊 **Measurable improvement** - 62.5% issue prevention
- 🔄 **Continuous feedback** - Real-time quality checks
- 📈 **Progressive enhancement** - Pattern database grows over time

## Customization

### Skip Specific Checks

Create `.quality-check-config`:
```bash
# Skip specific checks
SKIP_ASTYLE=false
SKIP_CPPCHECK=false
SKIP_REVIEW_PATTERNS=false
SKIP_BUILD=false
SKIP_TESTS=false
```

### Auto-Fix Configuration

Tell Claude your preferences:
```
"Always auto-fix code style without asking"
"Never auto-fix, just show issues"
"Ask before fixing anything"
```

Claude will remember your preference for the session.

## Troubleshooting

### Quality Check Fails

**Build Error:**
```
❌ Build failed: ltm4700.c:123: undefined reference to 'foo'
```
**Solution:** Fix the error, then re-run quality check

**Test Failure:**
```
❌ Unit tests failed: 3/245 tests failed
```
**Solution:** Fix failing tests, then re-run quality check

### False Positives

If you believe a warning is a false positive:
1. Ask Claude: "Why is this flagged?"
2. If confirmed false positive: Update `.cppcheckignore` or `.astyleignore`
3. Report to tool maintainers for future improvement

## Integration with Workflow

### Standard Development Flow

```
1. Implement feature
2. Ask: "Check code quality" ← AUTOMATED
3. Claude finds and fixes issues
4. Review changes: git diff
5. Commit with fixup workflow (see below)
6. Push and create PR
```

### Committing Quality Fixes

**🎯 RECOMMENDED: Use Fixup Commits**

When quality fixes are applied after creating your commit series, use **fixup commits** to maintain clean history:

```bash
# Step 1: Identify which commit modified each file
git log --oneline -- drivers/power/ltm4700/ltm4700.c
# Output: e3e812bd0 drivers: power: ltm4700: Add driver support for ltm4700

# Step 2: Stage files and create fixup commit for each original commit
git add drivers/power/ltm4700/ltm4700.c drivers/power/ltm4700/ltm4700.h
git commit --fixup=e3e812bd0

git add drivers/power/ltm4700/iio_ltm4700.c
git commit --fixup=7bf79390a

git add projects/ltm4700/src/common/common_data.c
git commit --fixup=fb0b93465

# Step 3: Squash fixups into original commits
git rebase -i --autosquash HEAD~9  # 6 original commits + 3 fixups

# Result: Clean 6-commit history with quality fixes integrated
```

**📚 Complete Fixup Workflow Guide:** [`.claude/docs/guides/git-workflow-guide.md`](guides/git-workflow-guide.md#fixup-commits-for-quality-fixes)

**Alternative for Single File:**
```bash
# If only fixing the most recent commit
git add file.c
git commit --amend --no-edit
```

### CI Integration

Quality checks also run in CI/CD:
- GitHub Actions: `.claude/workflows/ci-enhanced.yml`
- Pre-commit hooks: `.claude/tools/pre-commit/`
- SonarCloud: Weekly automated scans

Local checks **match** CI checks, so no surprises!

## Summary

The agentic quality workflow makes code review **interactive** and **proactive**:
- ✅ Automated detection
- ✅ Interactive fixes
- ✅ Learning from patterns
- ✅ Continuous improvement

Just ask Claude to check quality, and let it handle the rest! 🚀

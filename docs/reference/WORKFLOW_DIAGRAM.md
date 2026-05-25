# AI-Assisted Driver Development Workflow
**Visual Guide for New Developers**

---

## 🎯 Complete Adoption Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    INITIAL SETUP (One-Time)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Clone no-OS Repo │
                    └────────┬─────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │ Clone .claude/ into no-OS    │
              │ git clone <url> .claude      │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Initialize Submodules        │
              │ cd .claude                   │
              │ git submodule update --init  │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Install Pre-commit Hooks     │
              │ .claude/tools/pre-commit/    │
              │   install-hooks.sh          │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Validate Setup               │
              │ .claude/tools/pre-commit/    │
              │   validate-setup.sh          │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Configure Fork Workflow      │
              │ • Fork on GitHub             │
              │ • Set origin to fork         │
              │ • Add upstream remote        │
              └──────────┬───────────────────┘
                         │
                         ▼
                  ✅ READY FOR DEVELOPMENT
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  DRIVER DEVELOPMENT (Per Device)                 │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Sync with Upstream           │
              │ git fetch upstream           │
              │ git rebase upstream/main     │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Start Claude Code Session    │
              │ claude-code                  │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Request Driver Creation      │
              │ "Create a complete no-OS     │
              │  driver for <device>"        │
              └──────────┬───────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              AUTOMATED AI WORKFLOW (Claude Code)                 │
└─────────────────────────────────────────────────────────────────┘
                         │
    ┌────────────────────┴────────────────────┐
    │                                         │
    ▼                                         ▼
┌────────────────────┐           ┌────────────────────────┐
│ PHASE 0:           │           │ Runs Automatically:    │
│ Framework          │◄──────────┤ • Build system check   │
│ Validation         │           │ • Platform API verify  │
│ (MANDATORY)        │           │ • Test framework check │
└────────┬───────────┘           │ • IIO API validation   │
         │                       └────────────────────────┘
         ▼
    ✅ or ❌
         │
         ├─── ❌ FAIL ───► Fix Issues ───┐
         │                               │
         └─── ✅ PASS ──────────────────►│
                                         │
                                         ▼
                              ┌────────────────────┐
                              │ PHASE 1: Planning  │
                              │ (Interactive)      │
                              └─────────┬──────────┘
                                        │
                              ┌─────────▼──────────┐
                              │ Claude Presents:   │
                              │ • Device analysis  │
                              │ • Implementation   │
                              │   strategy         │
                              │ • 6-commit plan    │
                              └─────────┬──────────┘
                                        │
                              ┌─────────▼──────────┐
                              │ USER APPROVAL      │
                              │ Required?          │
                              └─────────┬──────────┘
                                        │
                    ┌───────────────────┴───────────────────┐
                    │                                       │
                    ▼                                       ▼
              Approve ✅                               Reject ❌
                    │                                       │
                    │                                       └──► Revise Plan
                    ▼
          ┌────────────────────┐
          │ PHASE 2:           │
          │ Implementation     │
          │ (Autonomous)       │
          └─────────┬──────────┘
                    │
         ┌──────────▼───────────┐
         │ Execute 6 Commits:   │
         │ 1. Core driver       │
         │ 2. IIO integration   │
         │ 3. Driver docs       │
         │ 4. Project files     │
         │ 5. Project docs      │
         │ 6. Unit tests        │
         └──────────┬───────────┘
                    │
                    ├──► Each Commit Triggers:
                    │    • Pre-commit hooks
                    │    • AStyle formatting
                    │    • Cppcheck analysis
                    │    • Pattern detection
                    │
                    ▼
          ┌────────────────────┐
          │ PHASE 3:           │
          │ Quality Assurance  │
          │ (Automatic)        │
          └─────────┬──────────┘
                    │
         ┌──────────▼───────────┐
         │ Automated Checks:    │
         │ • Code style ✓       │
         │ • Static analysis ✓  │
         │ • Build validation ✓ │
         │ • Unit tests (80%+) ✓│
         │ • Documentation ✓    │
         └──────────┬───────────┘
                    │
                    ▼
              ✅ COMPLETE
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SUBMISSION & REVIEW                            │
└─────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────▼───────────┐
         │ Developer Review:    │
         │ • Inspect commits    │
         │ • Test on hardware   │
         │ • Verify coverage    │
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ Push to Fork         │
         │ git push origin      │
         │   dev/<device>       │
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ Create Pull Request  │
         │ gh pr create --repo  │
         │   analogdevicesinc/  │
         │   no-OS              │
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ Code Review          │
         │ (Maintainer)         │
         └──────────┬───────────┘
                    │
         ┌──────────▼───────────┐
         │ Hardware Testing     │
         │ (If available)       │
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ ✅ MERGED            │
         └──────────────────────┘
```

---

## 📊 Key Decision Points

### 1. Framework Validation Fails ❌

**What Happens**:
- Claude reports specific failures (platform API, test framework, IIO structures, etc.)
- Provides troubleshooting guidance
- Implementation is **blocked** until fixed

**What To Do**:
1. Read `.claude/docs/framework-validation-troubleshooting.md`
2. Fix identified issues
3. Re-run validation or request driver again

### 2. Planning Requires Approval ✋

**What Happens**:
- Claude enters `EnterPlanMode`
- Presents comprehensive implementation plan
- **Waits for explicit user approval**

**What To Do**:
- Review the plan carefully
- Approve: "Yes, proceed with implementation"
- Reject: "No, please revise the plan to include X"

### 3. Pre-commit Hook Blocks Commit 🚫

**What Happens**:
- Git commit is rejected
- Specific issue reported (style, analysis, patterns)

**What To Do**:
- Review hook output
- Fix reported issues
- Commit again (DO NOT use `--no-verify`)

---

## 🔄 Parallel Workflows

### Multi-Device Development

```
Developer A              Developer B              Developer C
    │                        │                        │
    ▼                        ▼                        ▼
dev/adm1275            dev/ltc2978            dev/ad7091r5
    │                        │                        │
    ├─ Claude Session 1      ├─ Claude Session 2      ├─ Claude Session 3
    │                        │                        │
    ▼                        ▼                        ▼
6 commits                6 commits                6 commits
    │                        │                        │
    ▼                        ▼                        ▼
PR #1234                 PR #1235                 PR #1236
    │                        │                        │
    └────────────────────────┴────────────────────────┘
                             │
                             ▼
                    All merged to main
```

**Note**: Each developer works independently with their own Claude Code session.

---

## ⚡ Quick Commands Reference

### Daily Workflow

```bash
# 1. Sync with upstream
git fetch upstream && git rebase upstream/main

# 2. Create development branch
./.claude/tools/pre-commit/new-dev-branch.sh <device>

# 3. Start Claude Code
claude-code

# 4. In Claude: Request driver
"Create a complete no-OS driver for <device> <description>"

# 5. After implementation: Build
cd projects/<device> && make

# 6. Run tests
cd ../../tests/drivers/<category>/<device> && ceedling test:all

# 7. Push and create PR
git push origin dev/<device>
gh pr create --repo analogdevicesinc/no-OS
```

### Troubleshooting Commands

```bash
# Validate framework before requesting driver
./.claude/tools/scripts/framework_validation.sh <device> <category> <platform>

# Check environment setup
./.claude/tools/pre-commit/validate-setup.sh

# Re-install hooks if needed
./.claude/tools/pre-commit/install-hooks.sh

# Check git configuration
git config --global user.name
git config --global user.email
```

---

## 📈 Success Metrics

### What Good Looks Like

✅ **Framework Validation**: 100% pass rate before implementation
✅ **Commit Pattern**: Exactly 6 commits following standard sequence
✅ **Code Coverage**: 80%+ unit test coverage
✅ **Quality Checks**: All pre-commit hooks pass
✅ **Documentation**: All 4 docs present (driver README, project README, 2 Sphinx entries)
✅ **Build Success**: Clean builds across all target platforms
✅ **Review Time**: Reduced by 62.5% due to automated issue prevention

### Common Anti-Patterns to Avoid

❌ Using `git commit --no-verify` to bypass quality checks
❌ Skipping framework validation
❌ Creating generic device names (ltm470x instead of ltm4700)
❌ Fewer than 6 commits or wrong commit sequence
❌ Missing documentation files (especially project Sphinx entry)
❌ Less than 80% test coverage
❌ Including AI attribution in code or commits

---

## 🎓 Learning Resources

### For New Developers

**Read in this order**:
1. [GETTING_STARTED.md](GETTING_STARTED.md) - Complete onboarding (this document)
2. [framework-validation-lessons.md](framework-validation-lessons.md) - Critical failure patterns
3. [new-driver-workflow.md](new-driver-workflow.md) - Detailed workflow guide
4. [current-project-templates.md](current-project-templates.md) - Template standards

### For Advanced Users

**Explore these**:
1. [claude-code-integration-guide.md](claude-code-integration-guide.md) - AI workflow examples
2. [quality-assurance-guide.md](quality-assurance-guide.md) - QA automation patterns
3. [architecture-guide.md](architecture-guide.md) - Repository architecture
4. [no-os-review-pattern-analysis.md](no-os-review-pattern-analysis.md) - 6-month analysis

---

## 🔗 Related Documentation

- **Main Guide**: [CLAUDE.md](../CLAUDE.md)
- **Package Overview**: [README.md](../README.md)
- **Getting Started**: [GETTING_STARTED.md](GETTING_STARTED.md)
- **File Inventory**: [MANIFEST.md](MANIFEST.md)

---

**Last Updated**: 2026-05-22
**Diagram Version**: 1.0

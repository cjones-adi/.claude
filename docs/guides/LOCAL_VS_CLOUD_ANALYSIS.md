# Local vs Cloud Static Analysis Guide

Quick reference for choosing between local (cppcheck) and cloud (SonarCloud) analysis workflows.

---

## 🎯 Quick Decision Guide

**Use Local Analysis (cppcheck) when:**
- ✅ Developing actively (quick feedback loop)
- ✅ Working offline or on airplane
- ✅ Want privacy (code stays local)
- ✅ Need fast results (< 1 minute)
- ✅ Checking only your changes

**Use Cloud Analysis (SonarCloud) when:**
- ✅ Creating PR (team needs to see results)
- ✅ Want comprehensive metrics (complexity, duplication)
- ✅ Need historical trending
- ✅ Sharing results with team
- ✅ Require detailed code smells analysis

---

## 📊 Side-by-Side Comparison

### Local Analysis (NEW - True Local)

**Script**: `.claude/tools/pre-commit/local-static-analysis.sh`

```bash
# Quick check during development
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# Full analysis before PR
./.claude/tools/pre-commit/local-static-analysis.sh --full --html
```

**Outputs**:
- 📄 HTML report: `static-analysis-results/index.html` (viewable in browser)
- 📄 XML report: `static-analysis-results/cppcheck-result.xml` (for tools)
- 📟 Terminal summary: Immediate overview of issues

**Characteristics**:
- ⏱️ **Speed**: Fast (30-60 seconds typical)
- 🌐 **Network**: None required (fully offline)
- 🔒 **Privacy**: Code never leaves machine
- 📊 **Results**: Local HTML file
- 💰 **Cost**: Free (no limits)
- 🎯 **Focus**: Bugs, warnings, style, performance
- 📈 **History**: No historical tracking
- 👥 **Sharing**: Manual (export files)

**Best for**:
- Daily development workflow
- Quick sanity checks before commits
- Offline development
- Privacy-sensitive code

---

### Cloud Analysis (EXISTING - SonarCloud Upload)

**Script**: `.claude/tools/pre-commit/upload-to-sonarcloud.sh`
**⚠️ Note**: Despite "local" in name, this UPLOADS to SonarCloud

```bash
# Upload analysis to SonarCloud
export SONAR_TOKEN="your_token_here"
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only

# View results at: https://sonarcloud.io/dashboard
```

**Outputs**:
- 🌐 Web dashboard: `https://sonarcloud.io/dashboard?id=cjones-adi_no-OS`
- 📟 Terminal: Upload status only
- ⚠️ No local HTML report

**Characteristics**:
- ⏱️ **Speed**: Slower (upload time + processing)
- 🌐 **Network**: Required (uploads to cloud)
- 🔒 **Privacy**: Code uploaded to SonarCloud servers
- 📊 **Results**: Web browser required
- 💰 **Cost**: Free tier (public repos)
- 🎯 **Focus**: Comprehensive (bugs, smells, security, complexity, duplication)
- 📈 **History**: Full historical tracking
- 👥 **Sharing**: Easy (share URL)

**Best for**:
- Pre-PR comprehensive analysis
- Team collaboration
- Long-term quality tracking
- Detailed code quality metrics

---

## 🔄 Recommended Hybrid Workflow

### During Development (Local)

```bash
# 1. Make changes to code
vim drivers/power/ltm4700/ltm4700.c

# 2. Quick local check
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# 3. Fix issues, repeat
# ... iterate rapidly ...

# 4. Commit when local analysis is clean
git add .
git commit -s -m "drivers: power: ltm4700: Fix null pointer check"
```

**Benefits**: Fast iteration, no internet needed, immediate feedback

---

### Before PR (Cloud)

```bash
# 1. All local checks passed
./.claude/tools/pre-commit/local-static-analysis.sh --full

# 2. Upload to SonarCloud for team
export SONAR_TOKEN="your_token_here"
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only

# 3. View comprehensive results
# Visit: https://sonarcloud.io/dashboard?id=cjones-adi_no-OS&branch=dev/ltm4700

# 4. Address any additional issues found
# SonarCloud may find complexity or duplication issues that cppcheck missed

# 5. Create PR with clean SonarCloud results
gh pr create --title "..." --body "..."
```

**Benefits**: Comprehensive team-visible analysis, historical tracking

---

## 📋 Feature Comparison Table

| Feature | Local (cppcheck) | Cloud (SonarCloud) |
|---------|------------------|-------------------|
| **Results Location** | ✅ Local HTML file | ❌ Cloud website only |
| **Offline Use** | ✅ Yes | ❌ No (requires upload) |
| **Speed** | ✅ Fast (< 1 min) | Slower (upload delay) |
| **Privacy** | ✅ Code stays local | ❌ Code uploaded |
| **Setup** | ✅ Simple (already installed) | Medium (token required) |
| **HTML Report** | ✅ Yes (auto-generated) | ❌ No (web UI only) |
| **Terminal Output** | ✅ Yes (summary) | Limited |
| **Auto-open in Browser** | ✅ Yes (--open flag) | ❌ Manual web visit |
| **Changed Files Only** | ✅ Yes | ✅ Yes |
| **Bug Detection** | ✅ Good | ✅ Excellent |
| **Code Smells** | ⚠️ Basic | ✅ Comprehensive |
| **Security Hotspots** | ⚠️ Limited | ✅ Excellent |
| **Complexity Metrics** | ❌ No | ✅ Yes |
| **Duplication Detection** | ❌ No | ✅ Yes |
| **Historical Trends** | ❌ No | ✅ Yes |
| **Team Sharing** | ⚠️ Manual export | ✅ URL sharing |
| **CI Integration** | ✅ Easy | ✅ Easy |
| **Free Tier Limits** | ✅ None | ⚠️ Public repos only |

---

## 🛠️ Usage Examples

### Example 1: Quick Development Check

**Scenario**: Making changes to LTM4700 driver

```bash
# Edit code
vim drivers/power/ltm4700/ltm4700.c

# Quick local check (only your changes)
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# Output:
# ✅ Analysis completed!
# 📄 HTML Report: file:///home/cj/no-OS/static-analysis-results/index.html
#
# 📊 Analysis Summary
# Found 2 total issues:
#   🟡 Warning: 1 issues
#   🟢 Style: 1 issues
#
# Top issues:
#   1. [warning] drivers/power/ltm4700/ltm4700.c:145
#      uninitvar: Uninitialized variable: ret
#
# [Browser opens with detailed HTML report]
```

**Time**: ~30 seconds
**Result**: Fix the 2 issues, re-run, commit when clean

---

### Example 2: Pre-PR Comprehensive Check

**Scenario**: Ready to create PR for new driver

```bash
# 1. Full local analysis first
./.claude/tools/pre-commit/local-static-analysis.sh --full --html

# ✅ Clean! No issues found

# 2. Upload to SonarCloud for team visibility
export SONAR_TOKEN="sqa_abc123..."
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only

# 3. Check SonarCloud results
# Visit dashboard, fix any additional issues

# 4. Create PR
gh pr create --title "drivers: power: ltm4700: Add driver" \
  --body "SonarCloud: https://sonarcloud.io/dashboard?id=cjones-adi_no-OS&branch=dev/ltm4700"
```

**Time**: ~2-3 minutes total
**Result**: PR with both local and cloud analysis clean

---

### Example 3: Offline Development

**Scenario**: Working on airplane without internet

```bash
# Only local analysis works
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# SonarCloud would fail (no internet)
# ./tools/pre-commit/upload-to-sonarcloud.sh  # ❌ Would fail

# When back online, upload to SonarCloud
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```

**Benefit**: Can continue development workflow offline

---

## 🔧 Setup & Installation

### Local Analysis Setup

Already installed! Just use it:

```bash
# Check prerequisites
cppcheck --version          # Should show: Cppcheck 2.13.0
cppcheck-htmlreport --help  # If missing: pip3 install cppcheck-htmlreport

# Run first analysis
./.claude/tools/pre-commit/local-static-analysis.sh --help
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open
```

---

### Cloud Analysis Setup

Requires one-time token setup:

```bash
# 1. Get token from SonarCloud
# Visit: https://sonarcloud.io/account/security/
# Create token with name: "Local Development"

# 2. Set environment variable
export SONAR_TOKEN="sqa_your_token_here"

# 3. Optional: Add to ~/.bashrc for persistence
echo 'export SONAR_TOKEN="sqa_your_token_here"' >> ~/.bashrc

# 4. Run analysis
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```

---

## 💡 Pro Tips

### Tip 1: Alias for Quick Access

Add to `~/.bashrc`:

```bash
# Quick local analysis
alias qa='cd /home/cj/no-OS && ./tools/pre-commit/local-static-analysis.sh --changed-only --open'

# Full local analysis
alias qa-full='cd /home/cj/no-OS && ./tools/pre-commit/local-static-analysis.sh --full --html'

# Upload to SonarCloud
alias qa-cloud='cd /home/cj/no-OS && ./tools/pre-commit/upload-to-sonarcloud.sh --changed-only'
```

Usage:
```bash
# From any directory
qa          # Quick local check
qa-full     # Full local check
qa-cloud    # Upload to cloud
```

---

### Tip 2: Pre-Commit Hook Integration

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run quick local analysis before allowing commit

echo "Running quick static analysis..."
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only

# If failed, prevent commit
if [ $? -ne 0 ]; then
    echo "❌ Static analysis found issues. Fix before committing."
    echo "   Or use: git commit --no-verify to skip"
    exit 1
fi
```

---

### Tip 3: CI/CD Integration

Both tools can run in CI:

```yaml
# .github/workflows/static-analysis.yml
name: Static Analysis

on: [pull_request]

jobs:
  local-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run cppcheck
        run: |
          ./tools/pre-commit/local-static-analysis.sh --full
          # Upload HTML report as artifact

  cloud-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Upload to SonarCloud
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          ./tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```

---

## 🎯 Summary

### The Golden Rule

**Local first, cloud for comprehensive**:

1. ✅ Use **local analysis** during active development (fast feedback)
2. ✅ Use **cloud analysis** before PR (comprehensive review)
3. ✅ Both pass? You're ready to merge!

### Quick Commands

```bash
# Daily development
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# Before PR
./.claude/tools/pre-commit/local-static-analysis.sh --full
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```

---

**Documentation**:
- Local analysis: [/home/cj/no-OS/.claude/docs/archive/SONAR_LOCAL_ANALYSIS.md]
- SonarCloud: [/home/cj/no-OS/.claude/tools/pre-commit/sonar-local-guide.md]

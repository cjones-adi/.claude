# Static Analysis Quick Reference

One-page guide for choosing and using static analysis tools.

---

## 🎯 Quick Decision

**During development (fast feedback)**:
```bash
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open
```
↳ Opens local HTML report in browser (30-60 seconds)

**Before PR (comprehensive)**:
```bash
export SONAR_TOKEN="your_token"
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```
↳ Results at https://sonarcloud.io/dashboard

---

## 📊 Feature Comparison

| Need | Use | Why |
|------|-----|-----|
| Fast feedback | Local (cppcheck) | Results in < 1 min |
| Offline work | Local (cppcheck) | No internet needed |
| Privacy | Local (cppcheck) | Code stays local |
| Team sharing | Cloud (SonarCloud) | Share URL easily |
| Complexity metrics | Cloud (SonarCloud) | Deeper analysis |
| Historical trends | Cloud (SonarCloud) | Track over time |

---

## 🚀 Common Workflows

### Workflow 1: Daily Development

```bash
# 1. Make changes
vim drivers/power/ltm4700/ltm4700.c

# 2. Quick check (auto-opens browser)
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# 3. Fix issues shown in HTML report

# 4. Re-check until clean

# 5. Commit
git commit -s -m "..."
```

---

### Workflow 2: Pre-PR Comprehensive

```bash
# 1. Full local analysis
./.claude/tools/pre-commit/local-static-analysis.sh --full

# 2. Fix any issues

# 3. Upload to SonarCloud
export SONAR_TOKEN="..."
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only

# 4. Check https://sonarcloud.io/dashboard

# 5. Create PR when clean
gh pr create --title "..."
```

---

### Workflow 3: Offline Development (Airplane)

```bash
# Only local works (no internet)
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# When back online, upload
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```

---

## 💡 Pro Tips

### Add Aliases to ~/.bashrc

```bash
# Quick local check
alias qa='cd /home/cj/no-OS && ./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open'

# Full local check
alias qa-full='cd /home/cj/no-OS && ./.claude/tools/pre-commit/local-static-analysis.sh --full'

# Upload to cloud
alias qa-cloud='cd /home/cj/no-OS && export SONAR_TOKEN="..." && ./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only'
```

Then just: `qa` from any directory

---

## 🛠️ Setup

### Local Analysis (cppcheck)

Already installed! Just use it:

```bash
# Check version
cppcheck --version              # Should show: 2.13.0
cppcheck-htmlreport --help      # Should work (already installed)

# Test
./.claude/tools/pre-commit/local-static-analysis.sh --help
```

---

### Cloud Analysis (SonarCloud)

One-time token setup:

```bash
# 1. Get token from https://sonarcloud.io/account/security/
# 2. Set environment variable
export SONAR_TOKEN="sqa_your_token"

# 3. Optional: Add to ~/.bashrc
echo 'export SONAR_TOKEN="sqa_..."' >> ~/.bashrc

# 4. Test
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```

---

## 📄 Output Locations

### Local Analysis

```
static-analysis-results/
├── index.html              ← Open in browser
├── cppcheck-result.xml     ← For tools
├── stats.html
├── 0.html, 1.html, ...     ← Issue details
└── style.css
```

**View**: `file:///home/cj/no-OS/static-analysis-results/index.html`

---

### Cloud Analysis

**View**: https://sonarcloud.io/dashboard?id=cjones-adi_no-OS

**Local reference**: `.scannerwork/report-task.txt`

---

## 🔧 Troubleshooting

### Local Analysis Issues

```bash
# Issue: No changed files
git fetch upstream main
git diff --name-only upstream/main...HEAD

# Issue: Browser won't open
xdg-open static-analysis-results/index.html
# OR
wslview static-analysis-results/index.html
```

---

### Cloud Analysis Issues

```bash
# Issue: Token not set
echo $SONAR_TOKEN
export SONAR_TOKEN="..."

# Issue: Upload failed
# Check internet connection
# Verify token at https://sonarcloud.io/account/security/
```

---

## 📚 Full Documentation

- **Comprehensive analysis**: `.claude/docs/archive/SONAR_LOCAL_ANALYSIS.md`
- **Detailed comparison**: `.claude/docs/LOCAL_VS_CLOUD_ANALYSIS.md`
- **Session handover**: `.claude/docs/archive/SESSION_HANDOVER_2026-05-22_PART4.md`
- **SonarCloud guide**: `.claude/tools/pre-commit/sonar-local-guide.md`

---

## ⚡ TL;DR

```bash
# Development: Local, fast, offline
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# Pre-PR: Cloud, comprehensive, team-visible
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only
```

**Both clean? Ready to merge!** 🎉

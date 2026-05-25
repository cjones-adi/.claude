# SonarCloud "Local" Analysis - Problem Analysis & Solutions

**Date**: 2026-05-22
**Issue**: Current "local sonar" scripts don't provide true local viewing
**Status**: Analysis complete with solution recommendations

---

## 🔍 Problem Analysis

### Current State

The current `.claude/tools/pre-commit/upload-to-sonarcloud.sh` script:

1. **ALWAYS uploads to SonarCloud** - Results are stored on SonarCloud servers
2. **Requires web access** - Developers must visit https://sonarcloud.io to view results
3. **No local HTML reports** - No offline viewing capability
4. **Not truly "local"** - Despite the name, it's a cloud-based workflow

### What Happened to Preview Mode?

From [SESSION_HANDOVER_2026-05-22_PART3.md](SESSION_HANDOVER_2026-05-22_PART3.md):

> **Issue 2: Deprecated Preview Mode**
>
> **Problem**: SonarCloud 8.x error:
> ```
> ERROR The preview mode, along with the 'sonar.analysis.mode' parameter, is no more supported.
> ```
>
> **Root Cause**: Preview mode removed in SonarCloud Scanner 8.x
>
> **Fix Applied**: Removed preview mode from all scripts

**Result**: The only mode that could have avoided uploading (preview mode) was removed because it's deprecated.

### Current Script Behavior

```bash
# From upload-to-sonarcloud.sh line 143:
./tools/sonar/sonar-scanner "${scanner_args[@]}"

# This ALWAYS uploads results to SonarCloud
# Outputs to: .scannerwork/report-task.txt
```

**Contents of `.scannerwork/report-task.txt`:**
```
organization=cjones-adi
projectKey=cjones-adi_no-OS
serverUrl=https://sonarcloud.io
dashboardUrl=https://sonarcloud.io/dashboard?id=cjones-adi_no-OS&branch=staging%2Fltm4700-ga
```

**Conclusion**: Results are ONLY available via web browser at the SonarCloud dashboard URL.

---

## 🎯 What "Local Analysis" Should Mean

True local static analysis should provide:

1. ✅ **Runs entirely offline** - No internet required (except initial tool download)
2. ✅ **Results viewable locally** - HTML reports, terminal output, or JSON files
3. ✅ **No external dependencies** - No cloud service accounts needed
4. ✅ **Privacy** - Code never leaves local machine
5. ✅ **Fast feedback** - Immediate results without upload delays

**Current SonarCloud workflow**: ❌ Fails ALL of these requirements

---

## 💡 Solution Options

### Option 1: Use Cppcheck with HTML Reports ⭐ RECOMMENDED

**Status**: ✅ Already integrated in repository

The repository already has cppcheck configured (`ci/cppcheck.sh`):

```bash
# Current usage (CI only, no HTML output)
cppcheck -j${NUM_JOBS} --quiet --force --error-exitcode=1 \
  --enable=warning,style,performance $CPPCHECK_OPTIONS .
```

**Enhancement**: Add HTML report generation

```bash
# Create HTML report viewable in browser
cppcheck --enable=all \
  --xml --xml-version=2 \
  --suppressions-list=.cppcheckignore \
  --library=./ci/config.cppcheck \
  drivers/ include/ util/ iio/ 2> cppcheck-report.xml

# Convert to HTML
cppcheck-htmlreport \
  --source-dir=. \
  --title="no-OS Static Analysis" \
  --file=cppcheck-report.xml \
  --report-dir=cppcheck-html/
```

**Benefits**:
- ✅ Generates local HTML report (`cppcheck-html/index.html`)
- ✅ No cloud upload required
- ✅ Already installed (`cppcheck --version` → `Cppcheck 2.13.0`)
- ✅ Fast analysis (uses all CPU cores)
- ✅ Supports `--changed-only` via file filtering

**Limitations**:
- Less comprehensive than SonarCloud (no code smells, complexity metrics)
- No historical trending
- Basic HTML UI (not as polished as SonarCloud)

---

### Option 2: Local SonarQube Server

**Setup**: Run SonarQube Community Edition locally

```bash
# Using Docker
docker run -d --name sonarqube \
  -p 9000:9000 \
  sonarqube:community

# Then configure scanner to point to localhost
./tools/sonar/sonar-scanner \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=admin
```

**Benefits**:
- ✅ Full SonarQube features (same as SonarCloud)
- ✅ Local web UI (http://localhost:9000)
- ✅ Historical tracking
- ✅ No data leaves local machine

**Limitations**:
- ❌ Requires Docker or manual Java setup
- ❌ Resource intensive (1-2GB RAM minimum)
- ❌ Additional complexity (database, server management)
- ❌ Overkill for individual developer use

**Verdict**: Too complex for simple local analysis

---

### Option 3: Clang Static Analyzer with scan-build

**Setup**: Use LLVM's built-in analyzer

```bash
# Install
sudo apt install clang-tools

# Run analysis
scan-build --use-cc=gcc --status-bugs \
  -o scan-results \
  make -C projects/ltm4700/
```

**Benefits**:
- ✅ Excellent C/C++ analysis
- ✅ Generates local HTML reports
- ✅ Deep path-sensitive analysis
- ✅ Integration with build system

**Limitations**:
- Requires project to actually compile
- Slower than cppcheck (deeper analysis)
- May have false positives

---

### Option 4: Hybrid Approach (Best of Both Worlds)

**Local for development**:
```bash
# Fast, local feedback during development
./tools/local-static-analysis.sh --changed-only --html
# Opens: file:///.../cppcheck-html/index.html
```

**Cloud for comprehensive review**:
```bash
# Before PR, upload to SonarCloud for team visibility
./tools/sonar/run-sonarcloud-upload.sh --branch dev/ltm4700
# View at: https://sonarcloud.io/dashboard
```

**Verdict**: ⭐ **RECOMMENDED** - Best balance of speed and comprehensiveness

---

## 📋 Recommended Implementation Plan

### Phase 1: Create True Local Analysis Script

**File**: `.claude/tools/pre-commit/local-static-analysis.sh`

**Features**:
```bash
#!/bin/bash
# True local static analysis with HTML reports

Options:
  --changed-only     Analyze only changed files vs upstream/main
  --full            Analyze entire codebase
  --html            Generate HTML report (default: yes)
  --open            Open HTML report in browser automatically

Tools used:
  1. Cppcheck (primary, fast, good coverage)
  2. Clang static analyzer (optional, deeper analysis)
  3. Custom pattern checks (from review-checker.py)
```

**Example usage**:
```bash
# Quick check during development
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --open

# Full codebase before PR
./.claude/tools/pre-commit/local-static-analysis.sh --full --html

# Output:
# ✅ Analysis complete!
# 📊 Results: file:///home/cj/no-OS/static-analysis-results/index.html
#
# Summary:
#   🔴 High severity: 2 issues
#   🟡 Medium severity: 5 issues
#   🟢 Low severity: 12 issues
#
# Opening report in browser...
```

### Phase 2: Rename Existing SonarCloud Scripts

Make it clear what they actually do:

```bash
# Old (misleading name)
./.claude/tools/pre-commit/upload-to-sonarcloud.sh

# New (accurate name)
./.claude/tools/pre-commit/upload-to-sonarcloud.sh
./.claude/tools/pre-commit/sonarcloud-upload.sh
```

Update documentation to clarify:
- These scripts UPLOAD to SonarCloud (not local)
- Requires SONAR_TOKEN and internet connection
- Results viewed at https://sonarcloud.io

### Phase 3: Update Documentation

**Files to update**:
1. `.claude/tools/pre-commit/sonar-local-guide.md` → Rename to `sonarcloud-guide.md`
2. Create `.claude/tools/pre-commit/local-analysis-guide.md` for TRUE local workflow
3. Update `CLAUDE.md` to reflect both options

**New workflow documentation**:
```markdown
## Static Analysis Workflows

### Local Development (Fast, Offline)
Use cppcheck with HTML reports for immediate feedback:
- No internet required
- Results in < 30 seconds
- View in browser: file:///.../report.html

### Pre-PR Review (Comprehensive, Online)
Upload to SonarCloud for team visibility:
- Requires SONAR_TOKEN
- Full code quality metrics
- View at: https://sonarcloud.io
```

---

## 🔧 Implementation Details

### Cppcheck HTML Report Generation

**Installation** (if not installed):
```bash
# Install cppcheck-htmlreport
pip3 install cppcheck-htmlreport
# OR
sudo apt install cppcheck-htmlreport
```

**Script template**:
```bash
#!/bin/bash
# local-static-analysis.sh

CHANGED_ONLY=false
OPEN_BROWSER=false
OUTPUT_DIR="static-analysis-results"

# Parse changed files
if [ "$CHANGED_ONLY" = true ]; then
    FILES=$(git diff --name-only upstream/main...HEAD | grep -E '\.(c|h)$' | tr '\n' ' ')
    if [ -z "$FILES" ]; then
        echo "No C/C++ files changed"
        exit 0
    fi
    CPPCHECK_ARGS="$FILES"
else
    CPPCHECK_ARGS="drivers/ include/ util/ iio/"
fi

# Run cppcheck
echo "Running cppcheck analysis..."
cppcheck --enable=all \
    --inconclusive \
    --xml --xml-version=2 \
    --suppressions-list=.cppcheckignore \
    --library=./ci/config.cppcheck \
    -j$(nproc) \
    $CPPCHECK_ARGS 2> cppcheck-result.xml

# Generate HTML report
echo "Generating HTML report..."
mkdir -p "$OUTPUT_DIR"
cppcheck-htmlreport \
    --source-dir=. \
    --title="no-OS Static Analysis" \
    --file=cppcheck-result.xml \
    --report-dir="$OUTPUT_DIR"

# Print summary
echo ""
echo "✅ Analysis complete!"
echo "📊 Report: file://$(pwd)/$OUTPUT_DIR/index.html"

# Extract summary from XML
python3 -c "
import xml.etree.ElementTree as ET
tree = ET.parse('cppcheck-result.xml')
errors = tree.findall('.//error')
by_severity = {}
for error in errors:
    severity = error.get('severity', 'unknown')
    by_severity[severity] = by_severity.get(severity, 0) + 1

if not by_severity:
    print('\n✅ No issues found!')
else:
    print('\nSummary:')
    for sev in ['error', 'warning', 'style', 'performance', 'portability']:
        if sev in by_severity:
            icon = '🔴' if sev == 'error' else '🟡' if sev == 'warning' else '🟢'
            print(f'  {icon} {sev.capitalize()}: {by_severity[sev]} issues')
"

# Open in browser if requested
if [ "$OPEN_BROWSER" = true ]; then
    xdg-open "$OUTPUT_DIR/index.html" 2>/dev/null || \
    open "$OUTPUT_DIR/index.html" 2>/dev/null || \
    echo "Open manually: file://$(pwd)/$OUTPUT_DIR/index.html"
fi
```

---

## 📊 Comparison Matrix

| Feature | Current "Local" SonarCloud | True Local (Cppcheck) | Local SonarQube |
|---------|----------------------------|----------------------|-----------------|
| **Truly local** | ❌ Uploads to cloud | ✅ Fully offline | ✅ Fully local |
| **Local viewing** | ❌ Web browser to cloud | ✅ HTML file | ✅ localhost:9000 |
| **Setup complexity** | Medium (token required) | ✅ Low (already installed) | ❌ High (Docker/Java) |
| **Analysis speed** | Slow (upload delay) | ✅ Fast (30-60s) | Medium (local server) |
| **Result format** | Web dashboard | ✅ HTML + XML + JSON | Web dashboard |
| **Privacy** | ❌ Code uploaded | ✅ Stays local | ✅ Stays local |
| **Team sharing** | ✅ Easy (URL) | ❌ Manual (export files) | Medium (VPN access) |
| **Historical trends** | ✅ Yes | ❌ No | ✅ Yes |
| **Offline use** | ❌ No | ✅ Yes | ✅ Yes (after setup) |
| **Comprehensive** | ✅ Very high | Medium | ✅ Very high |

**Winner for "local analysis"**: ✅ **Cppcheck with HTML reports**

---

## 🎯 Recommendations

### Immediate Actions

1. **Create new local analysis script** using cppcheck with HTML output
2. **Rename existing scripts** to clarify they upload to SonarCloud
3. **Update all documentation** to reflect two distinct workflows:
   - Local analysis (cppcheck) for fast development feedback
   - Cloud analysis (SonarCloud) for comprehensive team review

### Long-term Enhancements

1. **Add scan-build integration** for deeper analysis (optional)
2. **Create unified dashboard** combining:
   - Cppcheck results
   - Review pattern analysis (already exists)
   - Unit test coverage (already exists)
   - SonarCloud link (for comprehensive view)
3. **Pre-commit integration** with configurable checks

### Documentation Updates

**Clarify terminology**:
- "Local analysis" = Runs offline, results viewable locally (cppcheck)
- "Cloud analysis" = Uploads to SonarCloud, results on website
- "Hybrid approach" = Use both (local for dev, cloud for PR)

---

## 📝 Next Steps

### For the User

1. **Decide on approach**:
   - Option A: Just rename existing scripts to be honest about cloud usage
   - Option B: Create true local analysis script (recommended)
   - Option C: Both (hybrid approach - best)

2. **Review proposed script** in this document

3. **Test workflow** with sample branch

### For Implementation

If proceeding with Option B or C:

```bash
# 1. Create the new script
cat > .claude/tools/pre-commit/local-static-analysis.sh << 'EOF'
[script content from above]
EOF
chmod +x .claude/tools/pre-commit/local-static-analysis.sh

# 2. Test it
./.claude/tools/pre-commit/local-static-analysis.sh --changed-only --html --open

# 3. Update documentation
# 4. Rename sonar scripts for clarity
```

---

## 🔗 Related Files

- Current "local" sonar script: `.claude/tools/pre-commit/upload-to-sonarcloud.sh`
- SonarCloud guide: `.claude/tools/pre-commit/sonar-local-guide.md`
- Cppcheck CI script: `ci/cppcheck.sh`
- Cppcheck config: `ci/config.cppcheck`
- Cppcheck suppressions: `.cppcheckignore`

---

**Conclusion**: The current "local sonar" workflow is misnamed - it's actually a "SonarCloud upload" workflow. To achieve true local analysis with viewable results, we should create a new cppcheck-based workflow while keeping SonarCloud for comprehensive cloud-based team analysis.

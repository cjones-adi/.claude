# SonarCloud Scanner Installation - Transferability Note

**Date**: 2026-05-22
**Issue**: Scanner currently at repo root, should be in `.claude/` for transferability

---

## 🎯 Current vs Desired State

### Current Installation (Not Transferable)
```
/home/cj/no-OS/
├── tools/
│   └── sonar/                     # ❌ At repo root
│       ├── sonar-scanner -> ...
│       ├── sonar-scanner-8.0.1.6346-linux-x64/  (extracted)
│       └── sonar-scanner-cli-8.0.1.6346-linux-x64.zip (59MB)
└── .claude/                       # Toolkit directory
```

**Problem**: When copying `.claude/` to another repo, sonar scanner is left behind

---

### Recommended Installation (Transferable)
```
/home/cj/no-OS/
└── .claude/
    ├── tools/
    │   └── sonar/                 # ✅ Within .claude/
    │       ├── sonar-scanner -> ...
    │       ├── sonar-scanner-8.0.1.6346-linux-x64/  (extracted)
    │       └── sonar-scanner-cli-8.0.1.6346-linux-x64.zip (59MB)
    └── .gitignore                 # Excludes sonar/ (large binaries)
```

**Benefits**: Complete toolkit transfers together

---

## 📦 Migration Options

### Option 1: Move Installation (Recommended)

```bash
# Move to .claude/
mkdir -p .claude/tools
mv tools/sonar .claude/tools/sonar

# Update symlink in sonar-project.properties if needed
# Scripts already use relative paths, should work automatically

# Clean up old location
rmdir tools 2>/dev/null || true
```

---

### Option 2: Fresh Install in .claude/

```bash
# Remove old installation
rm -rf tools/sonar

# Update setup script to use .claude/tools/sonar/
# Then run setup
./.claude/tools/pre-commit/setup-local-sonar.sh
```

---

### Option 3: Symlink (Not Recommended)

```bash
# Create symlink (for compatibility)
mkdir -p .claude/tools
ln -s ../../tools/sonar .claude/tools/sonar
```

**Why not**: Symlinks don't transfer well across repositories

---

## 🔧 Updated Setup Script

The `setup-local-sonar.sh` should be updated to install in `.claude/tools/sonar/`:

```bash
# In setup_directories() function:
setup_directories() {
    echo_info "Setting up directories..."

    # Use .claude/tools/sonar instead of repo root
    mkdir -p .claude/tools/sonar
    cd .claude/tools/sonar

    echo_success "Created .claude/tools/sonar directory"
}
```

**All scanner references** should use:
- `.claude/tools/sonar/sonar-scanner`

Instead of:
- `tools/sonar/sonar-scanner`

---

## 📊 Size Considerations

**SonarCloud Scanner Installation**:
- Zip file: ~59MB
- Extracted: ~167MB
- **Total**: ~226MB

**Why gitignore**:
- Large binary files
- Can be re-downloaded easily
- Different versions per OS
- Not source code

**Why in .claude/**:
- Part of AI development toolkit
- Transfers with toolkit
- Reinstalled once per repo
- Isolated from main project

---

## ✅ Current .claude/.gitignore

Already configured to exclude:

```gitignore
# SonarCloud scanner installation (large binaries)
sonar/
sonar-scanner*/
*.zip
*.tar.gz
*.deb
```

This means:
- ✅ Scanner won't be committed to git
- ✅ Keeps `.claude/` clean in git
- ✅ Must reinstall after transfer (expected)

---

## 🎯 Transfer Workflow

With sonar in `.claude/tools/sonar/`:

```bash
# 1. Copy toolkit (scanner excluded by .gitignore)
cp -r /source/repo/.claude /target/repo/

# 2. Reinstall scanner in new location
cd /target/repo
./.claude/tools/pre-commit/setup-local-sonar.sh

# 3. Verify
./.claude/tools/sonar/sonar-scanner --version
```

---

## 🔄 Recommendation

**For current repository**:
```bash
# Move to proper location
mkdir -p .claude/tools
mv tools/sonar .claude/tools/sonar

# Verify scripts still work
./.claude/tools/pre-commit/upload-to-sonarcloud.sh --help
```

**For new repositories**:
- Run `setup-local-sonar.sh` (updated version)
- Scanner installs to `.claude/tools/sonar/`
- Everything self-contained

---

## 📝 Documentation Updates Needed

Files to update with new path:

1. `.claude/tools/pre-commit/setup-local-sonar.sh` - Install location
2. `.claude/tools/pre-commit/upload-to-sonarcloud.sh` - Scanner reference
3. `.claude/tools/pre-commit/quick-sonarcloud-upload.sh` - Scanner reference
4. `sonar-project.properties` - If has absolute paths
5. Documentation - Update path references

**Search and replace**:
```bash
# Find references to old path
grep -r "tools/sonar" .claude/

# Update to new path
# tools/sonar → .claude/tools/sonar
```

---

## 🎉 Benefits of Moving to .claude/

1. **Complete Transferability**: Entire toolkit in one directory
2. **Clean Separation**: AI tools separate from project tools
3. **Easy Distribution**: Copy `.claude/`, run setup, done
4. **Version Control**: .gitignore handles large binaries
5. **Team Consistency**: Same structure across all repos

---

**Status**: Documented - Implementation pending user decision
**Impact**: Improves transferability
**Effort**: Low (simple move + path updates)
**Recommendation**: ✅ Move to `.claude/tools/sonar/`

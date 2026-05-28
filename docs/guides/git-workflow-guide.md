# Git Workflow Guide

**Comprehensive git workflow for no-OS driver development**

This guide provides the complete git workflow for contributing to the no-OS repository, including repository setup, branching strategy, commit patterns, and PR management.

## Repository Setup

### Standard Fork Workflow (Recommended)

The no-OS repository should be set up with two remotes for proper contribution workflow:

```bash
# Initial setup (one-time only)
# 1. Fork the repository on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/no-OS.git
cd no-OS

# 3. Set up remotes
git remote add upstream https://github.com/analogdevicesinc/no-OS.git
git remote set-url origin https://github.com/YOUR_USERNAME/no-OS.git

# Verify setup
git remote -v
# Should show:
# origin    https://github.com/YOUR_USERNAME/no-OS.git (fetch)
# origin    https://github.com/YOUR_USERNAME/no-OS.git (push)
# upstream  https://github.com/analogdevicesinc/no-OS.git (fetch)
# upstream  https://github.com/analogdevicesinc/no-OS.git (push)
```

### Staying Current with Upstream

```bash
# Regularly sync with upstream (recommended before starting new work)
git checkout main
git fetch upstream
git rebase upstream/main
git push origin main

# Or use the shorthand helper
git pull --rebase upstream main
git push origin main
```

**Remote Naming Convention:**
- **`upstream`** = Original ADI no-OS repository (analogdevicesinc/no-OS)
- **`origin`** = Your personal fork (YOUR_USERNAME/no-OS)

This setup allows you to:
- ✅ **Stay current** with latest no-OS changes
- ✅ **Push work** to your fork without affecting the main repository
- ✅ **Create PRs** from your fork back to upstream
- ✅ **Collaborate** with other developers safely

## Branching Strategy

### Branch Naming Convention

All development branches must follow the pattern: `dev/<specific_device_name>`

**🚨 Linux Kernel Principle**: Use explicit device names, never generic wildcards

```bash
# Sync with upstream before starting new work
git checkout main
git fetch upstream && git rebase upstream/main
git push origin main

# Create development branch for new device
git checkout -b dev/adm1275          # For ADM1275 PMBus device
git checkout -b dev/ltc2978          # For LTC2978 power supply
git checkout -b dev/ad7091r5         # For AD7091R5 ADC

# Work on your changes
git add drivers/power/adm1275/
git commit -s -m "drivers: power: adm1275: add initial driver implementation"

# Add project support
git add projects/adm1275/
git commit -s -m "projects: adm1275: add evaluation project"

# Push to your fork
git push origin dev/adm1275

# Submit PR from your fork to upstream
gh pr create --repo analogdevicesinc/no-OS \
             --title "drivers: power: adm1275: add support for ADM1275 PMBus monitor" \
             --body "Add driver for ADM1275 digital power monitor with I2C interface..."
```

### Branching Rules

- **Device drivers**: `dev/<specific_device_name>` (e.g., `dev/adm1275`, `dev/ltc2978`)
- **Family drivers**: `dev/<primary_device_name>` (e.g., `dev/ltm4700` for LTM470x family)
- **Platform support**: `dev/<device_name>-<platform>` (e.g., `dev/adm1275-maxim`)
- **Bug fixes**: `dev/<device_name>-fix-<issue>` (e.g., `dev/adm1275-fix-telemetry`)

**❌ Linux Principle Violations - Avoid these patterns:**
- ❌ `dev/ad717x` or `dev/adm127x` (generic family names)
- ❌ `dev/power-device` or `dev/adc-driver` (wildcard-style names)
- ❌ `feature/add-device` (too generic)
- ❌ `my-device-branch` (not following convention)
- ❌ `dev-branch` (not specific)
- ❌ `adm1275` (missing dev/ prefix)

**✅ Correct Linux-compliant patterns:**
- ✅ `dev/ltm4700` (even if supporting LTM4777 too - use primary device name)
- ✅ `dev/ad7175` (even if supporting AD7176/AD7177 - specific device identification)

## Common Git Operations

### Starting New Work

```bash
# Always start from updated main
git checkout main
git fetch upstream && git rebase upstream/main
git push origin main

# Create new development branch
./tools/pre-commit/new-dev-branch.sh adm1275
# This creates dev/adm1275 and switches to it
```

### During Development

```bash
# Regular commits
git add .
git commit -s -m "drivers: power: adm1275: implement telemetry functions"

# Periodic sync with upstream (if main branch has updates)
git fetch upstream
git rebase upstream/main  # Rebase your branch on latest upstream
```

### Preparing for PR

```bash
# Final sync and cleanup
git fetch upstream
git rebase upstream/main

# Push to your fork
git push origin dev/adm1275

# If you need to force push after rebasing (be careful!)
git push --force-with-lease origin dev/adm1275
```

### Creating Pull Request

```bash
# Create PR from your fork to upstream
gh pr create --repo analogdevicesinc/no-OS \
             --head YOUR_USERNAME:dev/adm1275 \
             --base main \
             --title "drivers: power: adm1275: add support for ADM1275 PMBus monitor" \
             --body "$(cat << 'EOF'
## Summary
- Add ADM1275 digital power monitor driver
- Support for voltage, current, and power telemetry
- PMBus interface with I2C communication
- MAX32655 and Linux platform support

## Testing
- [x] Hardware tested on MAX32655 evaluation board
- [x] IIO subsystem tested on Raspberry Pi 4
- [x] All pre-commit checks passed
- [x] Builds successfully on target platforms

## Documentation
- [x] Doxygen documentation complete
- [x] README added to project
- [x] Register definitions documented
EOF
)"
```

### After PR Merge

```bash
# Clean up local branches
git checkout main
git fetch upstream && git rebase upstream/main
git push origin main

# Delete merged branch
git branch -d dev/adm1275
git push origin --delete dev/adm1275
```

## Git Helper Commands

Create these aliases in your `.gitconfig` for easier workflow:

```ini
[alias]
    # Sync with upstream
    sync = !git fetch upstream && git rebase upstream/main

    # Push to origin with tracking
    pushup = !git push --set-upstream origin $(git branch --show-current)

    # Create signed commit
    cs = commit -s

    # Show branch status vs upstream
    status-upstream = !git log --oneline upstream/main..HEAD

    # Clean merged branches
    clean-branches = !git branch --merged | grep -E "dev/" | xargs -r git branch -d
```

Usage:
```bash
git sync                    # Update from upstream
git pushup                  # Push current branch to origin
git cs -m "commit message"  # Signed commit
git status-upstream         # See your commits vs upstream
git clean-branches          # Remove merged dev/ branches
```

## Commit Message Format

Follow this pattern consistently:

```
<scope>: <component>: <brief description>

[Optional detailed description]

```

**Examples:**
```
drivers: power: ltm4700: Add driver support for ltm4700
drivers: power: ltm4700: Add IIO support for ltm4700
drivers: power: ltm4700: Add README documentation for ltm4700
projects: ltm4700: Add project for ltm4700
projects: ltm4700: Add README documentation for project
tests: drivers: power: ltm4700: Add unit tests for ltm4700
```

## Commit Organization (MANDATORY 6-Commit Pattern)

**🚨 CRITICAL: ALL driver implementations MUST follow this exact 6-commit sequence:**

1. **Core Driver** - `drivers: <category>: <device>: Add driver support for <device>`
   - Header file (`<device>.h`) with complete API
   - Source file (`<device>.c`) with core implementation
   - Basic communication and device identification

2. **IIO Support** - `drivers: <category>: <device>: Add IIO support for <device>`
   - IIO header file (`iio_<device>.h`)
   - IIO source file (`iio_<device>.c`)
   - Complete Linux Industrial I/O integration

3. **Driver Documentation** - `drivers: <category>: <device>: Add README documentation for <device>`
   - Comprehensive `README.rst` with API reference
   - Usage examples and hardware setup instructions

4. **Project Implementation** - `projects: <device>: Add project for <device>`
   - Complete project structure (`Makefile`, `builds.json`, `src.mk`)
   - Source files (`src/main.c`, `src/common/`, `src/examples/`)
   - Multi-platform support configuration

5. **Project Documentation** - `projects: <device>: Add README documentation for project`
   - Project `README.rst` with build and usage instructions
   - Platform-specific setup guides

6. **Unit Tests** - `tests: drivers: <category>: <device>: Add unit tests for <device>`
   - Complete Ceedling test suite (`project.yml`)
   - Core driver tests (`test_<device>.c`) with 80%+ coverage
   - IIO tests (`test_iio_<device>.c`) and support files

## Required Sign-offs

All commits **must** be signed off:

```bash
git commit -s -m "commit message"
```

This adds: `Signed-off-by: Your Name <your.email@analog.com>`

**🚨 IMPORTANT**: Never include AI attribution in commits (no Co-Authored-By Claude, no "Generated with" mentions). Only use standard developer attribution.

## Advanced Git Operations

### Fixup Commits for Quality Fixes

When quality checks (code style, magic numbers, etc.) identify issues after creating your commit series, use **fixup commits** to organize corrections cleanly.

#### When to Use Fixup Commits

**Ideal scenarios:**
- ✅ After automated quality checks find issues (AStyle, review-checker.py)
- ✅ Post-commit code style improvements
- ✅ Removing redundant comments or magic numbers
- ✅ Small refactoring that logically belongs to an existing commit
- ✅ Addressing review feedback for specific commits

**Not appropriate for:**
- ❌ New features or functionality
- ❌ Bug fixes unrelated to the original commit
- ❌ Changes that span multiple original commits

#### Fixup Commit Workflow

**Step 1: Identify target commits**
```bash
# Find commits that modified the files you're fixing
git log --oneline -- path/to/file.c

# Example output:
# 7bf79390a drivers: power: ltm4700: Add IIO support for ltm4700
# e3e812bd0 drivers: power: ltm4700: Add driver support for ltm4700
```

**Step 2: Create fixup commits**
```bash
# Stage files and create fixup commit referencing target commit
git add drivers/power/ltm4700/ltm4700.c drivers/power/ltm4700/ltm4700.h
git commit --fixup=e3e812bd0

# Or use short hash
git commit --fixup=e3e812

# Create additional fixups for other commits
git add drivers/power/ltm4700/iio_ltm4700.c
git commit --fixup=7bf79390a

git add projects/ltm4700/src/common/common_data.c
git commit --fixup=fb0b93465
```

**Step 3: Verify fixup commits created**
```bash
git log --oneline -10

# Output shows fixup commits:
# 15e89b16e fixup! projects: ltm4700: Add project for ltm4700
# fbaeaeb19 fixup! drivers: power: ltm4700: Add IIO support for ltm4700
# 8914f1d5d fixup! drivers: power: ltm4700: Add driver support for ltm4700
# f31c79fe2 tests: drivers: power: ltm4700: Add unit tests for ltm4700
# bc5fa434f projects: ltm4700: Add README documentation for project
# fb0b93465 projects: ltm4700: Add project for ltm4700
# de1c942dd drivers: power: ltm4700: Add README documentation for ltm4700
# 7bf79390a drivers: power: ltm4700: Add IIO support for ltm4700
# e3e812bd0 drivers: power: ltm4700: Add driver support for ltm4700
```

**Step 4: Squash fixups into original commits**
```bash
# Interactive rebase with autosquash
# Count commits: original 6 commits + 3 fixups = 9 total
git rebase -i --autosquash HEAD~9

# Git automatically reorders and marks fixup commits:
# pick e3e812bd0 drivers: power: ltm4700: Add driver support for ltm4700
# fixup 8914f1d5d fixup! drivers: power: ltm4700: Add driver support for ltm4700
# pick 7bf79390a drivers: power: ltm4700: Add IIO support for ltm4700
# fixup fbaeaeb19 fixup! drivers: power: ltm4700: Add IIO support for ltm4700
# pick de1c942dd drivers: power: ltm4700: Add README documentation for ltm4700
# pick fb0b93465 projects: ltm4700: Add project for ltm4700
# fixup 15e89b16e fixup! projects: ltm4700: Add project for ltm4700
# pick bc5fa434f projects: ltm4700: Add README documentation for project
# pick f31c79fe2 tests: drivers: power: ltm4700: Add unit tests for ltm4700

# Save and exit - fixups are automatically squashed!
```

**Step 5: Verify clean history**
```bash
git log --oneline -6

# Output shows clean 6-commit pattern:
# a1b2c3d4e tests: drivers: power: ltm4700: Add unit tests for ltm4700
# b2c3d4e5f projects: ltm4700: Add README documentation for project
# c3d4e5f6g projects: ltm4700: Add project for ltm4700
# d4e5f6g7h drivers: power: ltm4700: Add README documentation for ltm4700
# e5f6g7h8i drivers: power: ltm4700: Add IIO support for ltm4700
# f6g7h8i9j drivers: power: ltm4700: Add driver support for ltm4700
```

#### Real-World Example: Quality Check Fixes

```bash
# Scenario: After running quality checks, found issues in multiple commits

# 1. Quality checker found 7 code style issues + 4 magic numbers
./.claude/tools/pre-commit/ci-check-changed.sh

# 2. Fix issues in driver core files
git add drivers/power/ltm4700/ltm4700.c drivers/power/ltm4700/ltm4700.h
git commit --fixup=e3e812bd0  # Core driver commit
# Created: fixup! drivers: power: ltm4700: Add driver support for ltm4700
# - Removed 6 redundant comments
# - Replaced magic number 0x7FF with LTM4700_LIN11_MANTISSA_MSK

# 3. Fix issues in IIO driver
git add drivers/power/ltm4700/iio_ltm4700.c
git commit --fixup=7bf79390a  # IIO commit
# Created: fixup! drivers: power: ltm4700: Add IIO support for ltm4700
# - Removed 1 redundant comment

# 4. Fix issues in project files
git add projects/ltm4700/src/common/common_data.c \
        projects/ltm4700/src/examples/basic/basic_example.c
git commit --fixup=fb0b93465  # Project commit
# Created: fixup! projects: ltm4700: Add project for ltm4700
# - Added I2C_FAST_MODE_HZ constant (replaced 400000)
# - Added TELEMETRY_DISPLAY_DELAY_MS constant (replaced 500)

# 5. Squash all fixups
git rebase -i --autosquash HEAD~9

# Result: Clean 6-commit history with all quality fixes integrated
```

#### Benefits of Fixup Commits

- ✅ **Clean History**: Quality fixes integrated into logical commits
- ✅ **Automatic Organization**: `--autosquash` handles reordering
- ✅ **Review Friendly**: Each commit remains focused on its purpose
- ✅ **Traceable**: Easy to see which commit received fixes
- ✅ **Revertable**: Each commit is complete and self-contained

#### Alternative: Amending Individual Commits

For single-commit fixes, you can also use `git commit --amend`:

```bash
# If only the most recent commit needs changes
git add file.c
git commit --amend --no-edit

# If earlier commit needs changes (more complex)
git rebase -i HEAD~3
# Mark commit as 'edit' instead of 'pick'
# Make changes
git add file.c
git commit --amend --no-edit
git rebase --continue
```

**Recommendation**: Use `--fixup` for multiple commits, `--amend` only for the most recent commit.

### Handling Merge Conflicts

```bash
# If conflicts occur during rebase
git status                  # See conflicted files
# Edit files to resolve conflicts
git add <resolved_files>
git rebase --continue

# If you need to abort the rebase
git rebase --abort
```

### Interactive Rebase for Clean History

```bash
# Clean up commits before submitting PR
git rebase -i HEAD~6        # Interactive rebase last 6 commits

# Options during interactive rebase:
# pick - use commit as-is
# squash - combine with previous commit
# fixup - like squash, but discard commit message
# reword - edit commit message
# edit - stop for amending
# drop - remove commit entirely
```

### Cherry-picking Changes

```bash
# Apply specific commit from another branch
git cherry-pick <commit-hash>

# Cherry-pick range of commits
git cherry-pick <start-hash>^..<end-hash>
```

---

This git workflow ensures clean contribution history, proper attribution, and smooth collaboration in the no-OS repository.
# Getting Started with AI-Assisted no-OS Driver Development
**Last Updated**: 2026-05-22
**Target Audience**: Developers adopting the AI-assisted workflow

---

## 📋 Overview

This guide walks you through setting up and using the complete AI-assisted driver development workflow for the no-OS repository. After setup, you'll be able to leverage Claude Code for automated driver creation, testing, and quality assurance.

---

## 🎯 Prerequisites

Before starting, ensure you have:

- ✅ no-OS repository cloned locally
- ✅ Git configured with your name and email (`git config --global user.name` and `user.email`)
- ✅ Python 3.x installed
- ✅ Claude Code CLI or VSCode extension installed
- ✅ Basic tools: `make`, `gcc`, `astyle` (optional), `cppcheck` (optional)

---

## 📦 Step 1: Clone the .claude Repository

Navigate to your no-OS repository and clone the .claude configuration:

```bash
# Navigate to your no-OS repository
cd /path/to/your/no-OS

# Clone the .claude repository (this contains all AI workflow configurations)
# Option A: If you have direct access to the .claude repository
git clone <.claude-repository-url> .claude

# Option B: If provided as a bundle/archive
tar -xzf claude-config.tar.gz -C .
```

**Expected Result**: You should now have a `.claude/` directory in your no-OS repository root.

**Verify**:
```bash
ls -la .claude/
# Should show: agents/, skills/, tools/, docs/, workflows/, config/, data/
```

**Make Install Script Executable**:
```bash
# Make the install script executable (it will make other scripts executable during setup)
chmod +x .claude/tools/pre-commit/install-hooks.sh
```

---

## 🔧 Step 2: Initialize Submodules (If Applicable)

If the .claude repository uses Git submodules for agents/skills:

```bash
cd .claude
git submodule update --init --recursive

# Verify symlinks are working
ls -la agents/ skills/
# Should show symlinks pointing to gen-ai-agents/
```

---

## ⚙️ Step 3: Run Initial Setup

Execute the setup scripts to configure your environment:

### 3.1 Install Pre-Commit Hooks

```bash
# From repository root
./.claude/tools/pre-commit/install-hooks.sh
```

**What this does**:
- Creates CLAUDE.md symlink in root directory (for Claude Code workflow access)
- Makes development scripts executable (framework_validation.sh, validate-setup.sh, new-dev-branch.sh)
- Installs git pre-commit hooks for code quality
- Sets up AStyle formatting checks
- Enables Cppcheck static analysis
- Configures branch naming validation
- Sets up commit message format checking

**Expected Output**:
```
🔧 Installing no-OS pre-commit hooks...
📄 Created CLAUDE.md symlink in root directory
✅ Pre-commit hooks installed successfully!

📋 What was installed:
  • CLAUDE.md symlink in root (for Claude Code workflow)
  • Branch naming convention validation (dev/<device_name>)
  • Code style checks (AStyle)
  • Static analysis (Cppcheck)
  • Build validation
  • Documentation checks
  • Commit message format validation
```

### 3.2 Validate Environment Setup

```bash
# Verify complete environment
./.claude/tools/pre-commit/validate-setup.sh
```

**What this checks**:
- Git repository configuration (origin/upstream remotes)
- Fork workflow setup
- Pre-commit hooks installation
- Development tools availability
- Branch setup and naming

**Expected Output**:
```
🔍 no-OS Development Environment Validation

✅ In a git repository
✅ Origin remote configured
✅ Upstream remote configured
✅ Origin appears to be a fork
...
✅ 🎉 Environment validation passed!
ℹ️  Ready for no-OS development
```

**Common Issues**:
- ⚠️ No upstream remote: Add with `git remote add upstream https://github.com/analogdevicesinc/no-OS.git`
- ⚠️ Origin not a fork: Fork the repository on GitHub first

---

## 🚀 Step 4: Configure Fork Workflow (If Not Already Done)

If you haven't set up a fork workflow:

```bash
# 1. Fork analogdevicesinc/no-OS on GitHub (via web interface)

# 2. Update your origin remote to point to your fork
git remote set-url origin https://github.com/YOUR_USERNAME/no-OS.git

# 3. Add upstream remote
git remote add upstream https://github.com/analogdevicesinc/no-OS.git

# 4. Verify remotes
git remote -v
# Should show:
# origin    https://github.com/YOUR_USERNAME/no-OS.git (fetch)
# origin    https://github.com/YOUR_USERNAME/no-OS.git (push)
# upstream  https://github.com/analogdevicesinc/no-OS.git (fetch)
# upstream  https://github.com/analogdevicesinc/no-OS.git (push)

# 5. Sync your main branch with upstream
git fetch upstream
git checkout main
git rebase upstream/main
git push origin main
```

---

## 🤖 Step 5: Start AI-Assisted Driver Development

Now you're ready to use Claude Code for driver development!

### 5.1 Start Claude Code Session

**Option A: Using Claude Code CLI**:
```bash
# Navigate to repository root
cd /path/to/your/no-OS

# Start Claude Code session
claude-code
```

**Option B: Using VSCode Extension**:
- Open no-OS repository in VSCode
- Open Claude Code panel (Ctrl+Shift+P → "Claude Code: Start Session")

### 5.2 Request Driver Development

Once in a Claude Code session, use this workflow:

#### **Example Request**: Create a New PMBus Driver

```
Create a complete no-OS driver for the ADM1275 PMBus hot-swap controller.

Device specifications:
- PMBus 1.2 compliant
- I2C interface, address 0x10
- Features: VIN, VOUT, IOUT, PIN, POUT, TEMP monitoring
- Hot-swap controller with overcurrent protection
```

#### **What Claude Code Will Do**:

**Phase 0: Framework Verification (Automatic)**
```
🔍 Running framework validation...
✅ Verifying build system patterns
✅ Validating platform APIs
✅ Checking test framework version
✅ Confirming IIO API compatibility
```

**Phase 1: Planning (Interactive)**
```
📋 Entering planning mode...

IMPLEMENTATION PLAN: ADM1275 PMBus Hot-Swap Controller Driver

ANALYSIS:
- Device: ADM1275 PMBus hot-swap controller
- Interface: I2C/PMBus (default address 0x10)
- Category: Power management (drivers/power/)
- Features: VIN, VOUT, IOUT, PIN, POUT, TEMP monitoring

IMPLEMENTATION STRATEGY:
1. Core Driver (drivers/power/adm1275/)
   - PMBus command set implementation
   - LINEAR11/LINEAR16 format conversion
   - Hot-swap control functions

2. IIO Integration (REQUIRED for monitoring devices)
   - 6 IIO channels: VIN, VOUT, IOUT, PIN, POUT, TEMP
   - Read-only monitoring interface

3. Project Structure (projects/adm1275/)
   - MAX32665 platform configuration
   - Basic telemetry monitoring example

4. Unit Testing (tests/drivers/power/adm1275/)
   - Ceedling/Unity/CMock framework
   - 80%+ code coverage

COMMIT SEQUENCE (6 commits):
1. drivers: power: adm1275: Add driver support for adm1275
2. drivers: power: adm1275: Add IIO support for adm1275
3. drivers: power: adm1275: Add README documentation for adm1275
4. projects: adm1275: Add project for adm1275
5. projects: adm1275: Add README documentation for project
6. tests: drivers: power: adm1275: Add unit tests for adm1275

Does this implementation plan look correct? Should I proceed?
```

**Your Response**: "Yes, proceed with the implementation"

**Phase 2: Autonomous Implementation**
```
✅ Creating development branch: dev/adm1275
✅ Commit 1/6: Core driver implementation
✅ Commit 2/6: IIO integration
✅ Commit 3/6: Driver documentation
✅ Commit 4/6: Project files
✅ Commit 5/6: Project documentation
✅ Commit 6/6: Unit tests

🎉 Implementation complete!

Summary:
- 6 commits created following no-OS standards
- Complete driver with IIO integration
- Multi-platform project configuration
- Unit tests with 85% code coverage
- All quality checks passed

Next steps:
1. Review the implementation
2. Test on hardware if available
3. Push to your fork: git push origin dev/adm1275
4. Create PR: gh pr create --repo analogdevicesinc/no-OS
```

---

## 📖 Step 6: Understanding the Workflow

### 6.1 Development Branch Management

```bash
# Create a new development branch (automated helper)
./.claude/tools/pre-commit/new-dev-branch.sh <device_name>

# Example:
./.claude/tools/pre-commit/new-dev-branch.sh adm1275
# Creates: dev/adm1275
```

### 6.2 Manual Framework Validation (Optional)

Before requesting driver development, you can manually validate the framework:

```bash
./.claude/tools/scripts/framework_validation.sh <device> <category> <platform>

# Example:
./.claude/tools/scripts/framework_validation.sh adm1275 power maxim
```

**This checks**:
- Build system compatibility
- Platform API availability
- Test framework version
- IIO API structures
- Reference driver patterns

### 6.3 Quality Checks (Automatic)

Pre-commit hooks automatically run on every commit:
- ✅ Code style (AStyle)
- ✅ Static analysis (Cppcheck)
- ✅ Branch naming validation
- ✅ Commit message format
- ✅ Documentation presence

**To bypass temporarily** (not recommended):
```bash
git commit --no-verify
```

---

## 🎯 Step 7: Complete Workflow Example

### End-to-End Driver Development

**1. Sync with upstream**:
```bash
git checkout main
git fetch upstream
git rebase upstream/main
git push origin main
```

**2. Start Claude Code**:
```bash
claude-code
```

**3. Request driver creation**:
```
Create a complete no-OS driver for LTC2978 8-channel PMBus power manager.
```

**4. Claude performs**:
- ✅ Framework validation
- ✅ Planning (waits for approval)
- ✅ Implementation (6 commits)
- ✅ Unit testing
- ✅ Quality checks

**5. Review and test**:
```bash
# Review commits
git log --oneline -6

# Build the project
cd projects/ltc2978
make

# Run unit tests
cd ../../tests/drivers/power/ltc2978
ceedling test:all
```

**6. Push and create PR**:
```bash
git push origin dev/ltc2978
gh pr create --repo analogdevicesinc/no-OS
```

---

## 🛠️ Troubleshooting

### Issue: Framework Validation Fails

**Symptom**: `framework_validation.sh` reports failures

**Solution**:
```bash
# Read detailed troubleshooting guide
cat .claude/docs/reference/framework-validation-troubleshooting.md

# Check platform-specific issues
cat .claude/docs/reference/framework-validation-lessons.md
```

### Issue: Pre-commit Hooks Block Commit

**Symptom**: Commit is rejected due to style or analysis issues

**Solution**:
```bash
# Fix AStyle formatting
astyle --options=.astylerc <file.c>

# Review Cppcheck warnings
cppcheck --enable=all <file.c>

# Then commit again
git add <file.c>
git commit -s
```

### Issue: Unit Tests Fail

**Symptom**: Ceedling reports test failures

**Solution**:
```bash
# Run tests with verbose output
cd tests/drivers/<category>/<device>
ceedling test:all

# Review test output
ceedling summary

# Check coverage
ceedling gcov:all utils:gcov
```

---

## 📚 Additional Resources

### Documentation

**Critical Guides** (read these first):
- `.claude/docs/reference/framework-validation-lessons.md` - Failure patterns and solutions
- `.claude/docs/guides/new-driver-workflow.md` - Complete development process
- `.claude/docs/templates/current-project-templates.md` - Project file templates

**Workflow Guides**:
- `.claude/docs/guides/claude-code-integration-guide.md` - AI workflow examples
- `.claude/docs/guides/git-workflow-guide.md` - Git best practices
- `.claude/docs/guides/quality-assurance-guide.md` - QA patterns

**Reference**:
- `.claude/CLAUDE.md` - Main integration guide
- `.claude/README.md` - Package overview
- `.claude/docs/MANIFEST.md` - Complete file listing

### Skills Reference

Claude Code has access to 40+ specialized skills for driver development:

**Quick reference**:
```bash
# In Claude Code session, invoke skills with:
/no-os-power        # Power management drivers
/no-os-adc          # ADC drivers
/no-os-imu          # IMU/accelerometer drivers
/datasheet-parsing  # Extract device specifications
/no-os-unit-testing # Unit testing framework
```

**Full skill list**: See `.claude/skills/` directory

### Agents Reference

Claude Code uses specialized agents for complex workflows:

- `driver-orchestrator.agent.md` - Complete workflow coordination
- `driver-planner-no-os.agent.md` - Planning agent
- `driver-coder-no-os.agent.md` - Implementation agent
- `driver-unit-tester-no-os.agent.md` - Testing agent
- `driver-code-reviewer-no-os.agent.md` - Review agent

**Full agent list**: See `.claude/agents/` directory

---

## ✅ Quick Reference Card

### Daily Workflow Commands

```bash
# 1. Start new driver development
./.claude/tools/pre-commit/new-dev-branch.sh <device>

# 2. Validate framework (optional, Claude does this automatically)
./.claude/tools/scripts/framework_validation.sh <device> <category> <platform>

# 3. Start Claude Code
claude-code

# 4. Request: "Create a complete no-OS driver for <device>"

# 5. After implementation, verify environment
./.claude/tools/pre-commit/validate-setup.sh

# 6. Build project
cd projects/<device>
make

# 7. Run unit tests
cd ../../tests/drivers/<category>/<device>
ceedling test:all

# 8. Push and create PR
git push origin dev/<device>
gh pr create --repo analogdevicesinc/no-OS
```

### Common AI Prompts

```
"Create a complete no-OS driver for <device> <description>"
"Add unit tests for the <device> driver"
"Review the code quality for <device> driver"
"Generate documentation for <device> driver"
"Fix the build errors in <device> project"
```

---

## 🎓 Learning Path

### Week 1: Setup and First Driver
1. ✅ Complete setup (Steps 1-4)
2. ✅ Create first driver with AI assistance
3. ✅ Review generated code and understand patterns
4. ✅ Run unit tests and understand coverage

### Week 2: Understanding the Framework
1. Read `.claude/docs/reference/framework-validation-lessons.md`
2. Study `.claude/docs/templates/driver-templates.md`
3. Review `.claude/docs/guides/architecture-guide.md`
4. Experiment with manual driver modifications

### Week 3: Advanced Features
1. Learn multi-platform builds
2. Explore IIO integration patterns
3. Study PMBus/ADC/IMU specific patterns
4. Contribute improvements to .claude repository

---

## 🚀 You're Ready!

**Next Step**: Start Claude Code and request your first driver!

```bash
claude-code
# Then: "Create a complete no-OS driver for <your-device>"
```

**Need Help?**
- Read: `.claude/CLAUDE.md` for comprehensive guide
- Check: `.claude/docs/` for detailed documentation
- Review: `.claude/skills/` for domain-specific guidance

---

**Happy Driver Development! 🎉**

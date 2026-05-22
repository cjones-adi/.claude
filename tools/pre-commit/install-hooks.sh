#!/bin/bash
# Install pre-commit hooks for no-OS development
# Run this from the repository root directory

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.git/hooks"
TOOLS_DIR="$REPO_ROOT/.claude/tools/pre-commit"

echo "🔧 Installing no-OS pre-commit hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Copy pre-commit hook
cp "$TOOLS_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

# Copy commit-msg hook (for commit message format checking)
cp "$TOOLS_DIR/commit-msg" "$HOOKS_DIR/commit-msg"
chmod +x "$HOOKS_DIR/commit-msg"

# Create config file for user customization
if [ ! -f "$REPO_ROOT/.pre-commit-config" ]; then
    cp "$TOOLS_DIR/pre-commit-config.example" "$REPO_ROOT/.pre-commit-config"
fi

echo "✅ Pre-commit hooks installed successfully!"
echo ""
echo "📋 What was installed:"
echo "  • Branch naming convention validation (dev/<device_name>)"
echo "  • Code style checks (AStyle)"
echo "  • Static analysis (Cppcheck)"
echo "  • Build validation"
echo "  • Documentation checks"
echo "  • Commit message format validation"
echo ""
echo "⚙️  Configuration:"
echo "  • Edit .pre-commit-config to customize checks"
echo "  • Use 'git commit --no-verify' to bypass hooks if needed"
echo ""
echo "🚀 Ready for development!"
echo ""
echo "💡 Run './.claude/tools/pre-commit/validate-setup.sh' to verify your complete environment"
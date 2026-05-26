#!/bin/bash
# Uninstall pre-commit hooks and cleanup no-OS development environment
# Run this from the repository root directory

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "🧹 Uninstalling no-OS pre-commit hooks and cleaning up..."
echo ""

# Track what was removed
REMOVED_COUNT=0

# Remove git hooks
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    rm "$HOOKS_DIR/pre-commit"
    echo "✅ Removed pre-commit hook"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

if [ -f "$HOOKS_DIR/commit-msg" ]; then
    rm "$HOOKS_DIR/commit-msg"
    echo "✅ Removed commit-msg hook"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
fi

# Remove CLAUDE.md symlink
if [ -L "$REPO_ROOT/CLAUDE.md" ]; then
    rm "$REPO_ROOT/CLAUDE.md"
    echo "✅ Removed CLAUDE.md symlink"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
elif [ -f "$REPO_ROOT/CLAUDE.md" ]; then
    echo "⚠️  Warning: CLAUDE.md exists but is not a symlink - skipping removal"
fi

# Remove pre-commit config file
if [ -f "$REPO_ROOT/.pre-commit-config" ]; then
    echo ""
    read -p "Remove .pre-commit-config file? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$REPO_ROOT/.pre-commit-config"
        echo "✅ Removed .pre-commit-config"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
        echo "ℹ️  Kept .pre-commit-config (may contain user customizations)"
    fi
fi

echo ""
if [ $REMOVED_COUNT -gt 0 ]; then
    echo "✅ Cleanup complete! Removed $REMOVED_COUNT item(s)"
else
    echo "ℹ️  Nothing to clean up - hooks were not installed"
fi

echo ""
echo "📋 What was cleaned up:"
echo "  • Git pre-commit hooks removed"
echo "  • Git commit-msg hook removed"
echo "  • CLAUDE.md symlink removed"
echo "  • .pre-commit-config optionally removed"
echo ""
echo "ℹ️  Note: The .claude/ directory was NOT removed"
echo "   To completely remove the workflow, run:"
echo "   rm -rf .claude/"
echo ""

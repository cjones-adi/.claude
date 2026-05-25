#!/bin/bash
# Quick SonarCloud analysis of changed files only

export SONAR_TOKEN="${SONAR_TOKEN:-YOUR_SONARCLOUD_TOKEN_HERE}"

echo "🚀 Quick SonarCloud check on your changes..."

./.claude/tools/pre-commit/upload-to-sonarcloud.sh --changed-only --export sonar-changes.json

if [ -f "sonar-changes.json" ]; then
    echo ""
    echo "📊 Quick Summary:"
    python3 -c "
import json
try:
    with open('sonar-changes.json', 'r') as f:
        data = json.load(f)

    issues = data.get('issues', [])
    if not issues:
        print('✅ No issues found in your changes!')
    else:
        print(f'Found {len(issues)} issues in your changes:')

        by_severity = {}
        for issue in issues:
            severity = issue.get('severity', 'UNKNOWN')
            by_severity[severity] = by_severity.get(severity, 0) + 1

        for severity in ['BLOCKER', 'CRITICAL', 'MAJOR', 'MINOR', 'INFO']:
            if severity in by_severity:
                icon = '🔴' if severity in ['BLOCKER', 'CRITICAL'] else '🟡' if severity == 'MAJOR' else '🟢'
                print(f'  {icon} {severity}: {by_severity[severity]} issues')

except Exception as e:
    print(f'Error processing results: {e}')
"

    echo ""
    echo "💡 For detailed analysis, share sonar-changes.json with Claude"
fi

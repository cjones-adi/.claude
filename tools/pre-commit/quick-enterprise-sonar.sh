#!/bin/bash
# Quick enterprise SonarQube analysis of changed files only

ENTERPRISE_SONAR_HOST="https://k8s.secad.analog.com/sonarqube"

if [ -z "$SONAR_TOKEN" ]; then
    echo "❌ SONAR_TOKEN not set"
    echo ""
    echo "Get your token:"
    echo "  1. Log in to ${ENTERPRISE_SONAR_HOST} with ADI credentials"
    echo "  2. Go to My Account > Security > Generate Token"
    echo "  3. Run: export SONAR_TOKEN=your_token_here"
    exit 1
fi

echo "🚀 Quick enterprise SonarQube check on your changes..."
echo "🏢 Server: ${ENTERPRISE_SONAR_HOST}"
echo ""

./.claude/tools/pre-commit/upload-to-enterprise-sonar.sh --changed-only --export sonar-changes.json

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
    echo "🔗 Or view in SonarQube: ${ENTERPRISE_SONAR_HOST}"
fi

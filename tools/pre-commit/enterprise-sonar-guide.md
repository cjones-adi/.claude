# Enterprise SonarQube Integration Guide

## Overview

This no-OS repository is configured to use ADI's enterprise SonarQube instance running on Kubernetes:

- **Server**: https://k8s.secad.analog.com/sonarqube
- **Version**: SonarQube Community Edition 10.7.0
- **Authentication**: ADI LDAP credentials
- **Database**: PostgreSQL with persistent storage
- **Project Key**: no-OS

## Getting Started

### 1. Get Authentication Token

1. Open https://k8s.secad.analog.com/sonarqube in your browser
2. Log in with your ADI credentials (LDAP authentication)
3. Click your profile icon (top right) → "My Account"
4. Go to "Security" tab
5. Generate a new token:
   - Name: `no-OS Development` (or your choice)
   - Type: User Token
   - Expiration: 30 days or as needed
6. **Copy the token immediately** (it won't be shown again)

### 2. Set Environment Variable

```bash
# Add to your ~/.bashrc or ~/.zshrc for persistence
export SONAR_TOKEN="your_generated_token_here"

# Or set temporarily for current session
export SONAR_TOKEN="your_token"
```

### 3. Run Local Analysis

```bash
# Quick check on changed files only
./.claude/tools/pre-commit/quick-enterprise-sonar.sh

# Full analysis
./.claude/tools/pre-commit/upload-to-enterprise-sonar.sh

# Changed files only
./.claude/tools/pre-commit/upload-to-enterprise-sonar.sh --changed-only

# Preview mode (local analysis, no upload)
./.claude/tools/pre-commit/upload-to-enterprise-sonar.sh --preview --export report.json
```

## Features

### Enterprise Benefits

✅ **Unlimited Analysis**: No restrictions on frequency or LOC
✅ **Branch Analysis**: Full support for all branches
✅ **Pull Request Decoration**: PR analysis with quality gate checks
✅ **Custom Quality Gates**: Enterprise-configured standards
✅ **Data Security**: Code stays within ADI network
✅ **LDAP Integration**: Seamless SSO with ADI credentials
✅ **Persistent History**: Long-term trend analysis

### Available Analysis

- **C/C++ Analysis**: Full cfamily analyzer with compilation database
- **Code Coverage**: Integration with Ceedling/Unity test coverage
- **Security Scanning**: OWASP vulnerabilities and security hotspots
- **Code Smells**: Maintainability issues detection
- **Duplication**: Code clone detection
- **Complexity**: Cyclomatic complexity analysis

## CI/CD Integration

### GitHub Actions Workflow

The repository includes `.claude/workflows/sonarqube-enterprise.yml` for automated analysis:

- Runs on push to main/staging/release branches
- Runs on pull requests to main
- Generates test coverage automatically
- Creates compilation database for enhanced C/C++ analysis
- Enforces quality gate before merge

### Required Secrets

Configure in GitHub repository settings:

```
SONAR_ENTERPRISE_TOKEN = <your_token_here>
```

## Quality Gates

### Default Quality Gate Criteria

The enterprise instance enforces these quality standards:

- **Coverage**: Minimum 80% on new code
- **Duplications**: Maximum 3% on new code
- **Maintainability**: A rating on new code
- **Reliability**: A rating on new code
- **Security**: A rating on new code
- **Security Hotspots**: All reviewed

### Viewing Quality Gate Status

1. Go to https://k8s.secad.analog.com/sonarqube
2. Navigate to "no-OS" project
3. Select your branch from dropdown
4. View Quality Gate status in dashboard

## Troubleshooting

### Token Authentication Failed

```bash
# Verify token is set
echo ${#SONAR_TOKEN}  # Should show token length (not 0)

# Regenerate token if expired
# Go to: https://k8s.secad.analog.com/sonarqube/account/security
```

### Scanner Not Found

```bash
# Re-run setup
./.claude/tools/pre-commit/setup-enterprise-sonar.sh
```

### Connection Issues

```bash
# Verify enterprise server is accessible
curl -I https://k8s.secad.analog.com/sonarqube

# Check if on ADI network (VPN may be required)
```

### Analysis Failed

```bash
# Check logs in .scannerwork/report-task.txt
cat .scannerwork/report-task.txt

# Run in verbose mode
./.claude/tools/sonar/sonar-scanner -X
```

## Migration from SonarCloud

If migrating from SonarCloud to enterprise:

1. **Backup**: Export existing quality profiles and rules
2. **Configuration**: Use enterprise configuration file
3. **Authentication**: Switch from SonarCloud token to enterprise token
4. **CI/CD**: Update GitHub Actions workflow
5. **Team Training**: Ensure team has LDAP access and tokens

## Advanced Usage

### Custom Quality Profile

1. Log in to SonarQube web interface
2. Go to "Quality Profiles"
3. Create custom profile based on "Sonar way"
4. Activate/deactivate rules as needed
5. Set as default for project

### Webhooks Integration

Configure webhooks for Slack/Teams notifications:

1. Go to Project Settings → Webhooks
2. Add webhook URL
3. Configure events (Quality Gate, Analysis Complete)

## Support

- **SonarQube Server**: https://k8s.secad.analog.com/sonarqube
- **Documentation**: Available in `.claude/docs/`
- **Issues**: Report in no-OS GitHub repository

## Comparison: SonarCloud vs Enterprise

| Feature | SonarCloud | Enterprise SonarQube |
|---------|-----------|---------------------|
| Authentication | Token only | LDAP + Token |
| Data Location | External | Internal (secure) |
| Branch Analysis | Limited | Unlimited |
| Cost | Free tier limits | No limits |
| Quality Gates | Shared | Custom |
| Plugins | Standard | Custom available |


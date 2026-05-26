#!/bin/bash
# Setup enterprise SonarQube scanner for no-OS development
# Uses internal ADI SonarQube instance on Kubernetes
# Server: https://k8s.secad.analog.com/sonarqube

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

SONAR_VERSION="6.2.1.4610"
SONAR_DIR="sonar-scanner-${SONAR_VERSION}-linux-x64"
SONAR_ZIP="sonar-scanner-cli-${SONAR_VERSION}-linux-x64.zip"
SONAR_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${SONAR_ZIP}"
ENTERPRISE_SONAR_HOST="https://k8s.secad.analog.com/sonarqube"

setup_directories() {
    echo_info "Setting up directories..."

    mkdir -p .claude/tools/sonar
    cd .claude/tools/sonar

    echo_success "Created tools/sonar directory"
}

download_scanner() {
    echo_info "Downloading SonarQube scanner..."

    if [ -f "$SONAR_ZIP" ]; then
        echo_info "Scanner already downloaded, skipping..."
        return 0
    fi

    if command -v wget > /dev/null 2>&1; then
        wget "$SONAR_URL"
    elif command -v curl > /dev/null 2>&1; then
        curl -L -o "$SONAR_ZIP" "$SONAR_URL"
    else
        echo_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi

    echo_success "Scanner downloaded"
}

install_scanner() {
    echo_info "Installing scanner..."

    if [ ! -f "$SONAR_ZIP" ]; then
        echo_error "Scanner zip file not found"
        exit 1
    fi

    # Extract if not already extracted
    if [ ! -d "$SONAR_DIR" ]; then
        unzip -q "$SONAR_ZIP"
        echo_success "Scanner extracted"
    else
        echo_info "Scanner already extracted"
    fi

    # Make executable
    chmod +x "${SONAR_DIR}/bin/sonar-scanner"

    # Create symlink for easy access
    ln -sf "${SONAR_DIR}/bin/sonar-scanner" sonar-scanner

    echo_success "Scanner installed"
}

create_project_config() {
    echo_info "Creating enterprise project configuration..."

    # Go back to repo root (from .claude/tools/sonar -> need 3 levels up)
    cd ../../..

    # Copy enterprise configuration from template
    if [ -f ".claude/config/sonar-project-enterprise.properties" ]; then
        cp .claude/config/sonar-project-enterprise.properties sonar-project.properties
        echo_success "Created sonar-project.properties from enterprise template"
    else
        echo_error "Enterprise template not found: .claude/config/sonar-project-enterprise.properties"
        exit 1
    fi
}

create_scanner_script() {
    echo_info "Creating enterprise scanner scripts..."

    # Create main scanner script
    cat > .claude/tools/pre-commit/upload-to-enterprise-sonar.sh << 'EOF'
#!/bin/bash
# Run local SonarQube analysis on development branch using enterprise instance
# Server: https://k8s.secad.analog.com/sonarqube

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

ENTERPRISE_SONAR_HOST="https://k8s.secad.analog.com/sonarqube"

usage() {
    echo "Run SonarQube analysis on local development branch (Enterprise)"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --changed-only     Analyze only files changed vs upstream/main"
    echo "  --preview         Run in preview mode (local analysis only)"
    echo "  --export FILE     Export results to file for Claude review"
    echo "  --help           Show this help"
    echo ""
    echo "Environment variables:"
    echo "  SONAR_TOKEN      Your enterprise SonarQube authentication token"
    echo "                   Get token from: ${ENTERPRISE_SONAR_HOST}/account/security"
    echo ""
    echo "Authentication:"
    echo "  1. Log in to ${ENTERPRISE_SONAR_HOST} with ADI credentials"
    echo "  2. Go to My Account > Security > Generate Token"
    echo "  3. Export token: export SONAR_TOKEN=your_token_here"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Full analysis"
    echo "  $0 --changed-only                     # Only changed files"
    echo "  $0 --preview --export sonar-report.json  # Preview + export"
}

check_prerequisites() {
    echo_info "Checking prerequisites..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo_error "Not in a git repository"
        exit 1
    fi

    # Check for scanner
    if [ ! -f ".claude/tools/sonar/sonar-scanner" ]; then
        echo_error "SonarQube scanner not found. Run ./.claude/tools/pre-commit/setup-enterprise-sonar.sh first"
        exit 1
    fi

    # Check for token
    if [ -z "$SONAR_TOKEN" ]; then
        echo_error "SONAR_TOKEN environment variable not set"
        echo_info "Get your token:"
        echo_info "  1. Log in to ${ENTERPRISE_SONAR_HOST} with ADI credentials"
        echo_info "  2. Go to My Account > Security > Generate Token"
        echo_info "  3. Run: export SONAR_TOKEN=your_token_here"
        exit 1
    fi

    # Check for sonar-project.properties
    if [ ! -f "sonar-project.properties" ]; then
        echo_error "sonar-project.properties not found"
        echo_info "Run ./.claude/tools/pre-commit/setup-enterprise-sonar.sh to create it"
        exit 1
    fi

    # Verify enterprise configuration
    if ! grep -q "k8s.secad.analog.com/sonarqube" sonar-project.properties; then
        echo_warning "Configuration may be for SonarCloud, not enterprise SonarQube"
        echo_info "Run ./.claude/tools/pre-commit/setup-enterprise-sonar.sh to update configuration"
    fi

    echo_success "Prerequisites check passed"
}

get_changed_files() {
    echo_info "Getting changed files vs upstream/main..."

    # Fetch upstream if it exists
    if git remote get-url upstream > /dev/null 2>&1; then
        git fetch upstream main > /dev/null 2>&1 || true
        BASE_BRANCH="upstream/main"
    else
        BASE_BRANCH="origin/main"
    fi

    # Get changed files
    changed_files=$(git diff --name-only "$BASE_BRANCH"...HEAD | grep -E '\.(c|h)$' | tr '\n' ',' | sed 's/,$//')

    if [ -z "$changed_files" ]; then
        echo_warning "No C/C++ files changed vs $BASE_BRANCH"
        return 1
    fi

    echo_success "Found changed files: $changed_files"
    echo "$changed_files"
}

run_analysis() {
    local mode="$1"
    local changed_only="$2"
    local export_file="$3"

    echo_info "Running enterprise SonarQube analysis..."
    echo_info "Server: ${ENTERPRISE_SONAR_HOST}"

    # Prepare scanner arguments
    scanner_args=(
        "-Dsonar.host.url=${ENTERPRISE_SONAR_HOST}"
        "-Dsonar.token=${SONAR_TOKEN}"
    )

    if [ "$mode" = "preview" ]; then
        scanner_args+=("-Dsonar.scanner.dumpToFile=${export_file:-sonar-report.json}")
        echo_info "Running in preview mode (local analysis only)"
    fi

    if [ "$changed_only" = "true" ]; then
        changed_files=$(get_changed_files)
        if [ $? -eq 0 ] && [ -n "$changed_files" ]; then
            scanner_args+=("-Dsonar.inclusions=$changed_files")
            echo_info "Analyzing only changed files"
        else
            echo_warning "No changed files found, analyzing all files"
        fi
    fi

    # Add export path if specified
    if [ -n "$export_file" ]; then
        scanner_args+=("-Dsonar.report.export.path=$export_file")
        echo_info "Will export results to: $export_file"
    fi

    # Run the scanner
    echo_info "Executing scanner..."
    current_branch=$(git branch --show-current)
    echo_info "Branch: $current_branch"

    # Add branch info if not main
    if [ "$current_branch" != "main" ]; then
        scanner_args+=("-Dsonar.branch.name=$current_branch")
        scanner_args+=("-Dsonar.branch.target=main")
    fi

    # Execute scanner
    ./.claude/tools/sonar/sonar-scanner "${scanner_args[@]}"

    echo_success "Analysis completed"
    echo_info "View results: ${ENTERPRISE_SONAR_HOST}/dashboard?id=no-OS&branch=${current_branch}"
}

process_results() {
    local export_file="$1"

    if [ -n "$export_file" ] && [ -f "$export_file" ]; then
        echo_info "Processing results for Claude review..."

        # Use our analyzer if available
        if [ -f ".claude/tools/pre-commit/sonar-report-analyzer.py" ]; then
            python3 .claude/tools/pre-commit/sonar-report-analyzer.py "$export_file" --export-claude "claude-sonar-review.json"
            echo_success "Claude review file generated: claude-sonar-review.json"
        fi
    fi
}

main() {
    local mode="publish"
    local changed_only="false"
    local export_file=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --changed-only)
                changed_only="true"
                shift
                ;;
            --preview)
                mode="preview"
                shift
                ;;
            --export)
                export_file="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    echo_info "🔍 Enterprise SonarQube Analysis"
    echo_info "Server: ${ENTERPRISE_SONAR_HOST}"
    echo ""

    check_prerequisites
    run_analysis "$mode" "$changed_only" "$export_file"
    process_results "$export_file"

    echo ""
    echo_success "🎉 Analysis completed!"

    if [ "$mode" = "preview" ]; then
        echo_info "Results are local only (preview mode)"
    else
        current_branch=$(git branch --show-current)
        echo_info "Results uploaded to enterprise SonarQube"
        echo_info "View: ${ENTERPRISE_SONAR_HOST}/dashboard?id=no-OS&branch=${current_branch}"
    fi

    if [ -f "claude-sonar-review.json" ]; then
        echo_info "📄 Share claude-sonar-review.json with Claude for detailed analysis"
    fi
}

main "$@"
EOF

    chmod +x .claude/tools/pre-commit/upload-to-enterprise-sonar.sh
    echo_success "Created .claude/tools/pre-commit/upload-to-enterprise-sonar.sh"

    # Create quick analysis script
    cat > .claude/tools/pre-commit/quick-enterprise-sonar.sh << 'EOF'
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
EOF

    chmod +x .claude/tools/pre-commit/quick-enterprise-sonar.sh
    echo_success "Created .claude/tools/pre-commit/quick-enterprise-sonar.sh"
}

create_integration() {
    echo_info "Creating integration documentation..."

    cat > .claude/tools/pre-commit/enterprise-sonar-guide.md << 'EOF'
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

EOF

    echo_success "Created enterprise integration guide"
}

verify_installation() {
    echo_info "Verifying installation..."

    # Check scanner executable
    if [ -x ".claude/tools/sonar/sonar-scanner" ]; then
        echo_success "Scanner executable: ✅"
    else
        echo_error "Scanner not executable"
        return 1
    fi

    # Check configuration
    if [ -f "sonar-project.properties" ]; then
        echo_success "Project configuration: ✅"
    else
        echo_error "Project configuration missing"
        return 1
    fi

    # Check scripts
    if [ -x ".claude/tools/pre-commit/upload-to-enterprise-sonar.sh" ]; then
        echo_success "Scanner script: ✅"
    else
        echo_error "Scanner script not executable"
        return 1
    fi

    # Check guide
    if [ -f ".claude/tools/pre-commit/enterprise-sonar-guide.md" ]; then
        echo_success "Integration guide: ✅"
    else
        echo_warning "Integration guide missing"
    fi

    echo_success "Installation verified"
}

print_next_steps() {
    cat << EOF

${GREEN}🎉 Enterprise SonarQube Scanner setup completed!${NC}

${BLUE}📋 What was installed:${NC}
  • SonarQube scanner (.claude/tools/sonar/)
  • Enterprise project configuration (sonar-project.properties)
  • Analysis scripts (.claude/tools/pre-commit/upload-to-enterprise-sonar.sh)
  • Quick check script (.claude/tools/pre-commit/quick-enterprise-sonar.sh)
  • Integration guide (.claude/tools/pre-commit/enterprise-sonar-guide.md)

${BLUE}🔑 Authentication Setup:${NC}
  1. Open ${ENTERPRISE_SONAR_HOST}
  2. Log in with ADI credentials (LDAP)
  3. My Account → Security → Generate Token
  4. Run: export SONAR_TOKEN=your_token_here

${BLUE}🚀 Quick start:${NC}
  # Set your token first
  export SONAR_TOKEN=your_token_here

  # Quick check on changed files
  ./.claude/tools/pre-commit/quick-enterprise-sonar.sh

  # Full analysis
  ./.claude/tools/pre-commit/upload-to-enterprise-sonar.sh --changed-only

${BLUE}📖 Full Documentation:${NC}
  Read: ./.claude/tools/pre-commit/enterprise-sonar-guide.md

${BLUE}🔗 SonarQube Server:${NC}
  ${ENTERPRISE_SONAR_HOST}

${YELLOW}💡 Tip:${NC} Add export SONAR_TOKEN to your ~/.bashrc for persistence

EOF
}

main() {
    echo_info "🔧 Setting up Enterprise SonarQube Scanner"
    echo_info "Server: ${ENTERPRISE_SONAR_HOST}"
    echo ""

    setup_directories
    download_scanner
    install_scanner
    create_project_config
    create_scanner_script
    create_integration
    verify_installation
    print_next_steps
}

main "$@"

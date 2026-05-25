#!/bin/bash
# Run local SonarCloud analysis on development branch

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

usage() {
    echo "Run SonarCloud analysis on local development branch"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --changed-only     Analyze only files changed vs upstream/main"
    echo "  --preview         Run in preview mode (no upload to SonarCloud)"
    echo "  --export FILE     Export results to file for Claude review"
    echo "  --help           Show this help"
    echo ""
    echo "Environment variables:"
    echo "  SONAR_TOKEN      Your SonarCloud authentication token"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Full analysis"
    echo "  $0 --changed-only                     # Only changed files"
    echo "  $0 --preview --export claude-report.json  # Preview + export"
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
        echo_error "SonarCloud scanner not found. Run ./.claude/tools/pre-commit/setup-local-sonar.sh first"
        exit 1
    fi

    # Check for token
    if [ -z "$SONAR_TOKEN" ]; then
        echo_error "SONAR_TOKEN environment variable not set"
        echo_info "Set your token: export SONAR_TOKEN=your_token"
        exit 1
    fi

    # Check for sonar-project.properties
    if [ ! -f "sonar-project.properties" ]; then
        echo_error "sonar-project.properties not found"
        echo_info "Run ./.claude/tools/pre-commit/setup-local-sonar.sh to create it"
        exit 1
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

    echo_info "Running SonarCloud analysis..."

    # Prepare scanner arguments
    scanner_args=("-Dsonar.login=$SONAR_TOKEN")

    if [ "$mode" = "preview" ]; then
        scanner_args+=("-Dsonar.analysis.mode=preview")
        echo_info "Running in preview mode (no upload)"
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
    fi

    # Execute scanner
    ./.claude/tools/sonar/sonar-scanner "${scanner_args[@]}"

    echo_success "Analysis completed"
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

    echo_info "🔍 Local SonarCloud Analysis"
    echo ""

    check_prerequisites
    run_analysis "$mode" "$changed_only" "$export_file"
    process_results "$export_file"

    echo ""
    echo_success "🎉 Analysis completed!"

    if [ "$mode" = "preview" ]; then
        echo_info "Results are local only (preview mode)"
    else
        echo_info "Results uploaded to SonarCloud"
    fi

    if [ -f "claude-sonar-review.json" ]; then
        echo_info "📄 Share claude-sonar-review.json with Claude for detailed analysis"
    fi
}

main "$@"

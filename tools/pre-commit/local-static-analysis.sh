#!/bin/bash
# True local static analysis with HTML reports
# No cloud upload - all results viewable locally

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
    echo "Run local static analysis with HTML reports"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --changed-only     Analyze only files changed vs upstream/main"
    echo "  --full            Analyze entire codebase (default)"
    echo "  --html            Generate HTML report (default: yes)"
    echo "  --open            Open HTML report in browser automatically"
    echo "  --output DIR      Output directory (default: static-analysis-results)"
    echo "  --help           Show this help"
    echo ""
    echo "Features:"
    echo "  ✅ Runs completely offline (no cloud upload)"
    echo "  ✅ Results viewable in browser (HTML report)"
    echo "  ✅ Fast feedback (30-60 seconds typical)"
    echo "  ✅ Privacy - code never leaves local machine"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Full analysis"
    echo "  $0 --changed-only --open              # Quick check, auto-open"
    echo "  $0 --full --output my-analysis/       # Custom output dir"
}

check_prerequisites() {
    echo_info "Checking prerequisites..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo_error "Not in a git repository"
        exit 1
    fi

    # Check for cppcheck
    if ! command -v cppcheck > /dev/null 2>&1; then
        echo_error "cppcheck not found"
        echo_info "Install: sudo apt install cppcheck"
        exit 1
    fi

    # Check for cppcheck-htmlreport
    if ! command -v cppcheck-htmlreport > /dev/null 2>&1; then
        echo_warning "cppcheck-htmlreport not found"
        echo_info "Install: pip3 install cppcheck-htmlreport"
        echo_info "Continuing with XML output only..."
    fi

    echo_success "Prerequisites check passed"
}

get_changed_files() {
    # Fetch upstream if it exists
    if git remote get-url upstream > /dev/null 2>&1; then
        git fetch upstream main > /dev/null 2>&1 || true
        BASE_BRANCH="upstream/main"
    else
        BASE_BRANCH="origin/main"
    fi

    # Get changed files (as array)
    mapfile -t changed_files_array < <(git diff --name-only "$BASE_BRANCH"...HEAD | grep -E '\.(c|h)$')

    if [ ${#changed_files_array[@]} -eq 0 ]; then
        return 1
    fi

    # Return array elements
    printf '%s\n' "${changed_files_array[@]}"
}

run_cppcheck() {
    local changed_only="$1"
    local output_dir="$2"

    echo_info "Running cppcheck analysis..."

    # Create output directory
    mkdir -p "$output_dir"

    # Determine what to analyze
    local -a files_to_analyze=()

    if [ "$changed_only" = "true" ]; then
        echo_info "Getting changed files vs upstream/main..."

        mapfile -t files_to_analyze < <(get_changed_files)

        if [ ${#files_to_analyze[@]} -eq 0 ]; then
            echo_warning "No C/C++ files changed, analyzing default directories"
            files_to_analyze=("drivers/" "include/" "util/" "iio/")
        else
            echo_success "Found ${#files_to_analyze[@]} changed file(s)"
        fi
    else
        echo_info "Analyzing entire codebase"
        files_to_analyze=("drivers/" "include/" "util/" "iio/")
    fi

    # Build cppcheck arguments array
    local -a cppcheck_args=(
        "--enable=warning,style,performance,portability"
        "--inconclusive"
        "--xml"
        "--xml-version=2"
        "--force"
        "--quiet"
    )

    # Add suppressions if file exists
    if [ -f ".cppcheckignore" ]; then
        cppcheck_args+=("--suppressions-list=.cppcheckignore")
    fi

    # Add library config if file exists
    if [ -f "./ci/config.cppcheck" ]; then
        cppcheck_args+=("--library=./ci/config.cppcheck")
    fi

    # Add include directories
    cppcheck_args+=("-I./include" "-I./drivers")

    # Add parallel processing (without unusedFunction which doesn't work with -j)
    cppcheck_args+=("-j$(nproc)")

    # Run analysis
    echo_info "Analyzing ${#files_to_analyze[@]} path(s)..."

    # Run cppcheck and capture output
    if cppcheck "${cppcheck_args[@]}" "${files_to_analyze[@]}" 2> "$output_dir/cppcheck-result.xml"; then
        echo_success "Analysis completed successfully"
    else
        # Check if XML file exists and has content
        if [ -s "$output_dir/cppcheck-result.xml" ]; then
            echo_success "Analysis completed with findings"
        else
            echo_error "Analysis failed - no output generated"
            return 1
        fi
    fi
}

generate_html_report() {
    local output_dir="$1"

    if ! command -v cppcheck-htmlreport > /dev/null 2>&1; then
        echo_warning "Skipping HTML generation (cppcheck-htmlreport not installed)"
        return 1
    fi

    echo_info "Generating HTML report..."

    if ! cppcheck-htmlreport \
        --source-dir=. \
        --title="no-OS Static Analysis Report" \
        --file="$output_dir/cppcheck-result.xml" \
        --report-dir="$output_dir" 2>/dev/null; then

        echo_warning "HTML report generation had issues (check XML file)"
        return 1
    fi

    echo_success "HTML report generated"
    return 0
}

generate_summary() {
    local output_dir="$1"
    local xml_file="$output_dir/cppcheck-result.xml"

    if [ ! -f "$xml_file" ]; then
        echo_warning "No results file found"
        return 1
    fi

    echo ""
    echo_info "📊 Analysis Summary"
    echo ""

    # Use python to parse XML and generate summary
    python3 << EOF
import xml.etree.ElementTree as ET
import sys

try:
    tree = ET.parse('$xml_file')
    root = tree.getroot()
    errors = root.findall('.//error')

    if not errors:
        print('✅ No issues found!')
        sys.exit(0)

    # Count by severity
    by_severity = {}
    for error in errors:
        severity = error.get('severity', 'unknown')
        by_severity[severity] = by_severity.get(severity, 0) + 1

    # Print total
    print(f'Found {len(errors)} total issue(s):')
    print('')

    # Print by severity with icons
    severity_order = ['error', 'warning', 'style', 'performance', 'portability', 'information']
    severity_icons = {
        'error': '🔴',
        'warning': '🟡',
        'style': '🟢',
        'performance': '🔵',
        'portability': '🟣',
        'information': 'ℹ️'
    }

    for severity in severity_order:
        if severity in by_severity:
            icon = severity_icons.get(severity, '•')
            print(f'  {icon} {severity.capitalize()}: {by_severity[severity]} issue(s)')

    # List first 5 errors for quick view
    print('')
    print('Top issues:')
    for i, error in enumerate(errors[:5]):
        msg_id = error.get('id', 'unknown')
        msg = error.get('msg', 'No message')
        severity = error.get('severity', 'unknown')

        # Find first location
        location = error.find('.//location')
        if location is not None:
            file_path = location.get('file', 'unknown')
            line = location.get('line', '?')
            print(f'  {i+1}. [{severity}] {file_path}:{line}')
            print(f'     {msg_id}: {msg}')

    if len(errors) > 5:
        print(f'  ... and {len(errors) - 5} more issue(s)')
        print('')
        print('  📄 View full report for details')

except Exception as e:
    print(f'Error parsing results: {e}')
    sys.exit(1)
EOF
}

open_report() {
    local output_dir="$1"
    local index_file="$output_dir/index.html"

    if [ ! -f "$index_file" ]; then
        echo_warning "HTML report not found: $index_file"
        return 1
    fi

    echo_info "Opening report in browser..."

    # Try different commands based on OS
    if command -v xdg-open > /dev/null 2>&1; then
        xdg-open "$index_file" 2>/dev/null &
    elif command -v open > /dev/null 2>&1; then
        open "$index_file" 2>/dev/null &
    elif command -v wslview > /dev/null 2>&1; then
        wslview "$index_file" 2>/dev/null &
    else
        echo_warning "Could not auto-open browser"
        echo_info "Open manually: file://$(pwd)/$index_file"
        return 1
    fi

    echo_success "Report opened in browser"
}

main() {
    local changed_only="false"
    local generate_html="true"
    local open_browser="false"
    local output_dir="static-analysis-results"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --changed-only)
                changed_only="true"
                shift
                ;;
            --full)
                changed_only="false"
                shift
                ;;
            --html)
                generate_html="true"
                shift
                ;;
            --open)
                open_browser="true"
                generate_html="true"  # Implied
                shift
                ;;
            --output)
                output_dir="$2"
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

    echo_info "🔍 Local Static Analysis"
    echo_info "No cloud upload - all results local"
    echo ""

    check_prerequisites

    if ! run_cppcheck "$changed_only" "$output_dir"; then
        echo_error "Analysis failed"
        exit 1
    fi

    if [ "$generate_html" = "true" ]; then
        if generate_html_report "$output_dir"; then
            echo ""
            echo_success "🎉 Analysis completed!"
            echo ""
            echo_info "📄 HTML Report: file://$(pwd)/$output_dir/index.html"
            echo_info "📄 XML Report:  $(pwd)/$output_dir/cppcheck-result.xml"
            echo ""
        fi
    fi

    generate_summary "$output_dir"

    if [ "$open_browser" = "true" ]; then
        echo ""
        open_report "$output_dir"
    fi

    echo ""
    echo_info "💡 Tips:"
    echo "   • Run with --changed-only for faster feedback during development"
    echo "   • Run with --full before creating PR for comprehensive check"
    echo "   • Add --open to automatically view results in browser"
    echo ""
}

main "$@"

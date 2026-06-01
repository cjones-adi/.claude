#!/usr/bin/env python3
"""
Example: Rule-based review checker output

This demonstrates how review-checker.py would be updated to reference
traceable rules from review_rules.json
"""

import json
import re
from pathlib import Path

class RuleBasedReviewChecker:
    """Enhanced review checker with rule references"""

    def __init__(self, rules_file):
        """Load rules from JSON file"""
        with open(rules_file, 'r') as f:
            rules_data = json.load(f)

        self.rules = {rule['rule_id']: rule for rule in rules_data['rules']}
        self.enabled_rules = {
            rule_id: rule for rule_id, rule in self.rules.items()
            if rule.get('enabled', True)
        }

    def check_file(self, file_path, content):
        """Check file against all enabled rules"""
        findings = []

        for rule_id, rule in self.enabled_rules.items():
            if rule['pattern'] is None:
                continue  # Skip rules without patterns

            # Check pattern
            matches = re.finditer(rule['pattern'], content, re.MULTILINE)

            for match in matches:
                line_num = content[:match.start()].count('\n') + 1

                finding = {
                    'rule_id': rule_id,
                    'category': rule['category'],
                    'severity': rule['severity'],
                    'title': rule['title'],
                    'description': rule['description'],
                    'file': file_path,
                    'line': line_num,
                    'matched_text': match.group(0)[:50],  # First 50 chars
                    'auto_fixable': rule['auto_fixable']
                }

                findings.append(finding)

        return findings

    def format_finding(self, finding):
        """Format a finding for display"""
        severity_colors = {
            'critical': '\033[91m',  # Red
            'error': '\033[91m',     # Red
            'warning': '\033[93m',   # Yellow
            'info': '\033[94m'       # Blue
        }
        reset = '\033[0m'

        severity = finding['severity']
        color = severity_colors.get(severity, '')

        output = []
        output.append(f"\n{color}[{severity.upper()}]{reset} {finding['file']}:{finding['line']}")
        output.append(f"  Rule {finding['rule_id']}: {finding['category']} - {finding['title']}")
        output.append(f"  {finding['description']}")

        if finding['auto_fixable']:
            output.append(f"  \033[92m✓ Auto-fixable\033[0m")

        return '\n'.join(output)

    def print_summary(self, findings):
        """Print summary of findings"""
        if not findings:
            print("\n\033[92m✓ No issues found\033[0m\n")
            return

        # Group by severity
        by_severity = {}
        for finding in findings:
            severity = finding['severity']
            by_severity.setdefault(severity, []).append(finding)

        # Print findings grouped by severity
        severity_order = ['critical', 'error', 'warning', 'info']

        for severity in severity_order:
            if severity not in by_severity:
                continue

            findings_list = by_severity[severity]
            print(f"\n{'='*70}")
            print(f"{severity.upper()}: {len(findings_list)} issue(s)")
            print(f"{'='*70}")

            for finding in findings_list:
                print(self.format_finding(finding))

        # Print summary
        print(f"\n{'='*70}")
        print("SUMMARY")
        print(f"{'='*70}")
        print(f"Total findings: {len(findings)}")
        for severity in severity_order:
            if severity in by_severity:
                count = len(by_severity[severity])
                print(f"  {severity.capitalize()}: {count}")

        auto_fixable = sum(1 for f in findings if f['auto_fixable'])
        if auto_fixable > 0:
            print(f"\n\033[92m{auto_fixable} issue(s) can be auto-fixed\033[0m")

        print(f"\n{'='*70}")
        print("RULE REFERENCES")
        print(f"{'='*70}")

        # List unique rules triggered
        unique_rules = set(f['rule_id'] for f in findings)
        for rule_id in sorted(unique_rules):
            rule = self.rules[rule_id]
            print(f"\n{rule_id}: {rule['title']}")
            print(f"  Category: {rule['category']}")
            print(f"  Severity: {rule['severity']}")
            print(f"  Rationale: {rule['rationale']}")

            if 'references' in rule:
                print(f"  References: {', '.join(rule['references'])}")

        print()


def example_usage():
    """Demonstrate rule-based checker output"""

    # Example file content with issues
    example_code = """
int ltm4700_read_vout(struct ltm4700_dev *dev, uint16_t *vout)
{
    int ret;
    uint8_t buf[2];

    ret = no_os_i2c_read(dev->i2c_desc, LTM4700_VOUT, buf, 2);
    *vout = (buf[1] << 8) | buf[0];  // ERR-001: Not checking ret first

    return 0;
}

int helper_function(void)  // DOC-001: Missing documentation
{
    return 0;
}

void set_voltage(uint16_t voltage)  // NAME-001: Wrong naming pattern
{
    vals[0] = (uint16_t)voltage;  // TYPE-001: No overflow check
}
"""

    print("\n" + "="*70)
    print("EXAMPLE: Rule-Based Review Checker Output")
    print("="*70)

    # Simulate findings
    findings = [
        {
            'rule_id': 'ERR-001',
            'category': 'Error Handling',
            'severity': 'critical',
            'title': 'Read/Write Command Result Validation',
            'description': 'Read/Write command should be evaluated first before consuming the resulting value',
            'file': 'drivers/power/ltm4700/ltm4700.c',
            'line': 8,
            'matched_text': 'ret = no_os_i2c_read...*vout = ',
            'auto_fixable': False
        },
        {
            'rule_id': 'DOC-001',
            'category': 'Documentation',
            'severity': 'warning',
            'title': 'Missing Function Documentation',
            'description': 'Public functions must have Doxygen documentation',
            'file': 'drivers/power/ltm4700/ltm4700.c',
            'line': 13,
            'matched_text': 'int helper_function(void)',
            'auto_fixable': False
        },
        {
            'rule_id': 'TYPE-001',
            'category': 'Type Safety',
            'severity': 'critical',
            'title': 'IIO Data Type Overflow Risk',
            'description': 'Always validate range before casting IIO values to prevent hardware damage',
            'file': 'drivers/power/ltm4700/iio_ltm4700.c',
            'line': 20,
            'matched_text': 'vals[0] = (uint16_t)voltage',
            'auto_fixable': False
        }
    ]

    # Create mock checker with rules
    checker = RuleBasedReviewChecker('/home/cj/no-OS/.claude/data/review_rules.json')
    checker.print_summary(findings)


if __name__ == "__main__":
    example_usage()

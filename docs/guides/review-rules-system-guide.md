# Review Rules System Guide

## Overview

The review rules system transforms the pattern-based review process into a traceable, systematic approach where every finding references a specific rule with a unique ID.

## Benefits

### 1. **Traceability**
- Every finding references a specific rule ID (e.g., ERR-001, DOC-001)
- Easy to track which rules are most frequently violated
- Clear documentation trail for compliance and quality metrics

### 2. **Systematic Improvement**
- Rules can be enabled/disabled individually
- Severity levels guide prioritization (critical → error → warning → info)
- Statistics track rule violations over time

### 3. **Developer Education**
- Each rule includes rationale explaining why it matters
- Examples show both bad and good patterns
- References link to detailed documentation

### 4. **Automation Support**
- Rules marked as `auto_fixable` can be automatically corrected
- Pattern-based detection for consistent enforcement
- Integration with CI/CD pipelines

## Rule Structure

Each rule in `review_rules.json` follows this format:

```json
{
  "rule_id": "ERR-001",
  "category": "Error Handling",
  "severity": "critical",
  "title": "Read/Write Command Result Validation",
  "description": "Read/Write command should be evaluated first before consuming the resulting value",
  "rationale": "Using values from failed I2C/SPI operations can lead to undefined behavior and hardware damage",
  "pattern": "ret\\s*=\\s*(no_os_)?[is]2c_(read|write).*\\n.*(?!if\\s*\\(\\s*ret)",
  "examples": [
    {
      "bad": "ret = no_os_i2c_write(dev->i2c_desc, buf, 2);\nvalue = buf[0];",
      "good": "ret = no_os_i2c_write(dev->i2c_desc, buf, 2);\nif (ret)\n\treturn ret;\nvalue = buf[0];",
      "pr": 2845,
      "file": "drivers/power/ltm4686/ltm4686.c"
    }
  ],
  "auto_fixable": false,
  "enabled": true,
  "detection_confidence": "high",
  "references": [
    ".claude/docs/reference/error-handling-patterns.md"
  ]
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `rule_id` | string | Unique identifier (format: `CATEGORY-###`) |
| `category` | string | Rule category (Error Handling, Documentation, etc.) |
| `severity` | string | `critical`, `error`, `warning`, or `info` |
| `title` | string | Short descriptive title |
| `description` | string | Detailed description of the issue |
| `rationale` | string | Why this rule matters (consequences) |
| `pattern` | string/null | Regex pattern for automated detection |
| `examples` | array | Bad/good code examples with PR references |
| `auto_fixable` | boolean | Can this be automatically corrected? |
| `enabled` | boolean | Is this rule currently active? |
| `detection_confidence` | string | `high`, `medium`, or `low` |
| `references` | array | Links to detailed documentation (optional) |

## Rule ID Format

Rule IDs follow the pattern: `PREFIX-###`

### Prefixes by Category

| Prefix | Category | Example |
|--------|----------|---------|
| `ERR` | Error Handling | `ERR-001` |
| `DOC` | Documentation | `DOC-001` |
| `ORG` | Code Organization | `ORG-001` |
| `TYPE` | Type Safety | `TYPE-001` |
| `HDR` | Header Guards/Includes | `HDR-001` |
| `TEST` | Testing | `TEST-001` |
| `CONST` | Constants/Magic Numbers | `CONST-001` |
| `STYLE` | Code Style | `STYLE-001` |
| `NAME` | Naming Convention | `NAME-001` |
| `PLAT` | Platform Compatibility | `PLAT-001` |
| `GEN` | General/Uncategorized | `GEN-001` |

## Severity Levels

### Critical
- **Impact**: Can cause hardware damage, data corruption, or system crashes
- **Examples**: Buffer overflows, unchecked voltage calculations, race conditions
- **Action**: Must be fixed before merge

### Error
- **Impact**: Will cause bugs or incorrect behavior
- **Examples**: Missing error handling, resource leaks, logic errors
- **Action**: Should be fixed before merge

### Warning
- **Impact**: May cause issues or reduces code quality
- **Examples**: Missing documentation, magic numbers, poor naming
- **Action**: Fix recommended, exceptions allowed with justification

### Info
- **Impact**: Style or minor improvements
- **Examples**: Whitespace, formatting, minor refactoring suggestions
- **Action**: Nice to have, not blocking

## Usage

### 1. Migrating Existing Patterns to Rules

```bash
cd /home/cj/no-OS/.claude/tools/pre-commit

# Interactive migration (recommended for first time)
python3 migrate-patterns-to-rules.py
# Choose option 1 for interactive rule creation

# Batch create templates for review
python3 migrate-patterns-to-rules.py
# Choose option 2 to create templates for all categories
```

### 2. Adding New Rules Manually

Edit `.claude/data/review_rules.json` and add a new rule:

```json
{
  "rule_id": "ERR-003",
  "category": "Error Handling",
  "severity": "error",
  "title": "Uninitialized Variable Usage",
  "description": "Variables must be initialized before use",
  "rationale": "Uninitialized variables contain garbage values and lead to undefined behavior",
  "pattern": "int\\s+(\\w+);\\s*\n.*\\1(?!\\s*=)",
  "examples": [
    {
      "bad": "int value;\nreturn value;",
      "good": "int value = 0;\nreturn value;",
      "pr": 0,
      "file": "example.c"
    }
  ],
  "auto_fixable": false,
  "enabled": true,
  "detection_confidence": "medium"
}
```

### 3. Running Rule-Based Reviews

```bash
# Example output with rule references
python3 review-checker-rules-example.py
```

**Example Output:**

```
==================================================================
CRITICAL: 2 issue(s)
==================================================================

[CRITICAL] drivers/power/ltm4700/ltm4700.c:8
  Rule ERR-001: Error Handling - Read/Write Command Result Validation
  Read/Write command should be evaluated first before consuming the resulting value

[CRITICAL] drivers/power/ltm4700/iio_ltm4700.c:20
  Rule TYPE-001: Type Safety - IIO Data Type Overflow Risk
  Always validate range before casting IIO values to prevent hardware damage

==================================================================
WARNING: 1 issue(s)
==================================================================

[WARNING] drivers/power/ltm4700/ltm4700.c:13
  Rule DOC-001: Documentation - Missing Function Documentation
  Public functions must have Doxygen documentation

==================================================================
SUMMARY
==================================================================
Total findings: 3
  Critical: 2
  Warning: 1

==================================================================
RULE REFERENCES
==================================================================

ERR-001: Read/Write Command Result Validation
  Category: Error Handling
  Severity: critical
  Rationale: Using values from failed I2C/SPI operations can lead to undefined behavior and hardware damage

TYPE-001: IIO Data Type Overflow Risk
  Category: Type Safety
  Severity: critical
  Rationale: Silent overflow in voltage/current calculations can cause hardware damage (e.g., 300V instead of 3.3V)
  References: .claude/docs/reference/iio-data-type-safety.md

DOC-001: Missing Function Documentation
  Category: Documentation
  Severity: warning
  Rationale: API documentation is essential for maintainability and user guidance
```

### 4. Updating Rule Statistics

After running reviews, update statistics in `review_rules.json`:

```json
"rule_statistics": {
  "ERR-001": {
    "total_occurrences": 47,
    "prs_affected": [2845, 2812, 2790],
    "last_seen": "2026-06-01"
  }
}
```

### 5. Disabling Rules

Temporarily disable a rule:

```json
{
  "rule_id": "STYLE-001",
  "enabled": false,
  ...
}
```

## Integration with Existing Tools

### review-checker.py

Update the existing review-checker.py to:

1. Load rules from `review_rules.json`
2. Apply pattern matching for rules with patterns
3. Output findings with rule references
4. Generate summary with rule statistics

### CI/CD Integration

```bash
# In pre-commit hook or CI pipeline
python3 review-checker.py --rules-file .claude/data/review_rules.json \
                          --output-format json \
                          --fail-on-severity critical
```

### SonarCloud Integration

Map SonarCloud findings to internal rules:

```json
{
  "rule_id": "ERR-001",
  "sonarcloud_rule": "c:S1234",
  ...
}
```

## Maintaining Rules

### Monthly Review Process

1. **Analyze new PR comments** from the last month
2. **Identify new patterns** not covered by existing rules
3. **Create new rules** or update existing ones
4. **Update statistics** for triggered rules
5. **Review disabled rules** - can they be re-enabled?

### Rule Quality Checklist

- [ ] Rule ID is unique and follows naming convention
- [ ] Title is clear and descriptive
- [ ] Description explains the issue
- [ ] Rationale explains the impact/consequences
- [ ] At least one example showing bad vs. good code
- [ ] Severity is appropriate for the impact
- [ ] Pattern (if provided) is tested and accurate
- [ ] References to documentation are valid

### Deprecating Rules

When a rule is no longer needed:

```json
{
  "rule_id": "OLD-001",
  "enabled": false,
  "deprecated": true,
  "deprecated_reason": "Superseded by ERR-005",
  "deprecated_date": "2026-06-01",
  ...
}
```

## Best Practices

### 1. Write Clear Descriptions
- Use active voice
- Be specific about what's wrong
- Explain the expected behavior

### 2. Provide Good Examples
- Include real code from actual PRs when possible
- Show both the problem and the solution
- Reference the PR where the pattern was found

### 3. Set Appropriate Severity
- Consider actual impact, not just theoretical
- Critical = can cause damage or crashes
- Error = will cause bugs
- Warning = reduces quality
- Info = style preferences

### 4. Maintain Patterns
- Test regex patterns thoroughly
- Account for whitespace variations
- Consider false positive rate
- Document pattern limitations

### 5. Track Metrics
- Monitor which rules are most frequently triggered
- Track reduction in violations over time
- Measure auto-fix effectiveness

## Example Workflow

### Adding a New Rule from PR Comment

1. **Reviewer leaves comment on PR #2900:**
   ```
   Missing null pointer check after malloc. This will cause a segfault
   if allocation fails.
   ```

2. **Identify appropriate rule category:**
   - Category: Error Handling
   - Severity: critical (can crash)

3. **Generate rule ID:**
   - Check existing ERR-### rules
   - Next available: ERR-004

4. **Create rule:**
   ```json
   {
     "rule_id": "ERR-004",
     "category": "Error Handling",
     "severity": "critical",
     "title": "Missing NULL Check After Allocation",
     "description": "Pointers returned from malloc/calloc must be checked for NULL before use",
     "rationale": "Failed allocations return NULL, dereferencing NULL causes segmentation fault",
     "pattern": "(malloc|calloc|realloc)\\([^)]+\\);\\s*\n(?!.*if\\s*\\()",
     "examples": [
       {
         "bad": "ptr = malloc(sizeof(*ptr));\nptr->field = value;",
         "good": "ptr = malloc(sizeof(*ptr));\nif (!ptr)\n\treturn -ENOMEM;\nptr->field = value;",
         "pr": 2900,
         "file": "drivers/example/example.c"
       }
     ],
     "auto_fixable": false,
     "enabled": true,
     "detection_confidence": "high"
   }
   ```

5. **Test the pattern:**
   ```bash
   # Test on example code
   python3 review-checker.py --test-rule ERR-004 --file example.c
   ```

6. **Update statistics:**
   ```json
   "rule_statistics": {
     "ERR-004": {
       "total_occurrences": 1,
       "prs_affected": [2900],
       "last_seen": "2026-06-01"
     }
   }
   ```

## Files Structure

```
.claude/
├── data/
│   ├── review_patterns_6month.json    # Original pattern database (legacy)
│   └── review_rules.json              # New rule-based system
├── tools/
│   └── pre-commit/
│       ├── migrate-patterns-to-rules.py      # Migration tool
│       ├── review-checker.py                  # Original checker (to be updated)
│       ├── review-checker-rules-example.py    # Example rule-based output
│       └── auto-update-rules.py               # Automated rule updates (to be created)
└── docs/
    └── guides/
        └── review-rules-system-guide.md       # This file
```

## Next Steps

1. **Complete migration** of existing patterns to rules using the migration tool
2. **Update review-checker.py** to use rule-based output
3. **Create auto-update-rules.py** to automatically update rule statistics from new PRs
4. **Document all existing rules** with complete examples and rationales
5. **Set up CI integration** to enforce critical rules
6. **Train team** on the rule system and how to add new rules

## Support

For questions or suggestions about the rule system:
- Review existing rules in `.claude/data/review_rules.json`
- Check migration guide in `.claude/tools/pre-commit/migrate-patterns-to-rules.py`
- See example output in `.claude/tools/pre-commit/review-checker-rules-example.py`

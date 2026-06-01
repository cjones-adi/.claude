#!/usr/bin/env python3
"""
Migrate review_patterns_6month.json to rule-based review_rules.json

This script helps convert existing pattern examples into traceable rules with unique IDs.
"""

import json
import sys
from pathlib import Path
from datetime import datetime

def load_patterns(patterns_file):
    """Load existing patterns from 6-month analysis"""
    with open(patterns_file, 'r') as f:
        return json.load(f)

def load_rules(rules_file):
    """Load existing rules"""
    if not rules_file.exists():
        return None
    with open(rules_file, 'r') as f:
        return json.load(f)

def generate_rule_id(category, existing_ids):
    """Generate next available rule ID for a category"""
    # Category to prefix mapping
    prefix_map = {
        "Error Handling": "ERR",
        "Documentation": "DOC",
        "Code Organization": "ORG",
        "Type Safety": "TYPE",
        "Header Guards/Includes": "HDR",
        "Testing": "TEST",
        "Constants/Magic Numbers": "CONST",
        "Code Style": "STYLE",
        "Naming Convention": "NAME",
        "Platform Compatibility": "PLAT",
        "Uncategorized": "GEN"
    }

    prefix = prefix_map.get(category, "GEN")

    # Find highest number for this prefix
    max_num = 0
    for rule_id in existing_ids:
        if rule_id.startswith(prefix + "-"):
            try:
                num = int(rule_id.split("-")[1])
                max_num = max(max_num, num)
            except (IndexError, ValueError):
                continue

    return f"{prefix}-{max_num + 1:03d}"

def create_rule_template(rule_id, category, pattern_example):
    """Create a rule template from a pattern example"""
    return {
        "rule_id": rule_id,
        "category": category,
        "severity": "warning",  # Default, should be reviewed
        "title": "TODO: Add descriptive title",
        "description": pattern_example.get("body", "TODO: Add description"),
        "rationale": "TODO: Explain why this matters",
        "pattern": None,  # TODO: Add regex pattern if applicable
        "examples": [
            {
                "bad": "TODO: Add bad example",
                "good": "TODO: Add good example",
                "pr": pattern_example.get("pr", 0),
                "file": pattern_example.get("path", "N/A")
            }
        ],
        "auto_fixable": False,
        "enabled": True,
        "detection_confidence": "medium"
    }

def analyze_pattern_for_rule_suggestions(pattern_text):
    """Analyze pattern text and suggest rule details"""
    suggestions = {
        "severity": "warning",
        "auto_fixable": False
    }

    # Critical keywords
    if any(word in pattern_text.lower() for word in [
        "crash", "segfault", "memory leak", "undefined behavior",
        "hardware damage", "overflow", "buffer overrun"
    ]):
        suggestions["severity"] = "critical"

    # Error keywords
    elif any(word in pattern_text.lower() for word in [
        "error", "fail", "invalid", "null pointer", "missing check"
    ]):
        suggestions["severity"] = "error"

    # Info keywords
    elif any(word in pattern_text.lower() for word in [
        "style", "formatting", "whitespace", "typo"
    ]):
        suggestions["severity"] = "info"

    # Auto-fixable patterns
    if any(word in pattern_text.lower() for word in [
        "tab", "space", "indent", "header guard", "whitespace"
    ]):
        suggestions["auto_fixable"] = True

    return suggestions

def interactive_rule_creation(patterns_data, rules_data):
    """Interactively create rules from patterns"""
    existing_ids = [rule["rule_id"] for rule in rules_data["rules"]]

    print("\n=== Pattern to Rule Migration ===\n")
    print(f"Found {len(patterns_data['category_counts'])} categories")
    print(f"Currently {len(rules_data['rules'])} rules defined\n")

    # Show category statistics
    print("Category Statistics:")
    for category, count in sorted(patterns_data['category_counts'].items(),
                                  key=lambda x: x[1], reverse=True):
        print(f"  {category}: {count} occurrences")

    print("\n" + "="*60)

    # Process each category
    for category, examples in patterns_data['category_examples'].items():
        if category == "Uncategorized":
            continue  # Skip uncategorized for now

        print(f"\n\n{'='*60}")
        print(f"Category: {category}")
        print(f"Total examples: {len(examples)}")
        print(f"{'='*60}\n")

        # Group similar patterns
        print("Sample patterns:")
        for i, example in enumerate(examples[:5], 1):  # Show first 5
            print(f"\n{i}. PR #{example['pr']} - {example.get('path', 'N/A')}")
            print(f"   Comment: {example['body'][:100]}...")

        response = input(f"\nCreate rule(s) for {category}? (y/n/s=skip): ").lower()

        if response == 's' or response == 'n':
            continue

        if response == 'y':
            num_rules = input(f"How many distinct rules for this category? [1]: ")
            num_rules = int(num_rules) if num_rules.strip() else 1

            for i in range(num_rules):
                rule_id = generate_rule_id(category, existing_ids)
                print(f"\n--- Creating Rule {rule_id} ---")

                title = input(f"Rule title: ")
                description = input(f"Description: ")

                # Get severity with suggestion
                pattern_suggestion = analyze_pattern_for_rule_suggestions(description)
                severity = input(f"Severity (critical/error/warning/info) [{pattern_suggestion['severity']}]: ")
                severity = severity.strip() or pattern_suggestion['severity']

                rationale = input(f"Rationale (why this matters): ")

                auto_fix = input(f"Auto-fixable? (y/n) [{'y' if pattern_suggestion['auto_fixable'] else 'n'}]: ")
                auto_fixable = auto_fix.lower() == 'y' if auto_fix.strip() else pattern_suggestion['auto_fixable']

                # Create rule
                new_rule = {
                    "rule_id": rule_id,
                    "category": category,
                    "severity": severity,
                    "title": title,
                    "description": description,
                    "rationale": rationale,
                    "pattern": None,  # Can be added later
                    "examples": [],
                    "auto_fixable": auto_fixable,
                    "enabled": True,
                    "detection_confidence": "medium"
                }

                rules_data["rules"].append(new_rule)
                existing_ids.append(rule_id)

                print(f"✓ Created rule {rule_id}")

    # Update metadata
    rules_data["metadata"]["total_rules"] = len(rules_data["rules"])
    rules_data["metadata"]["last_updated"] = datetime.now().strftime("%Y-%m-%d")

    return rules_data

def batch_create_rules_from_patterns(patterns_data, rules_data, category=None):
    """Batch create rule templates from all patterns"""
    existing_ids = [rule["rule_id"] for rule in rules_data["rules"]]

    categories_to_process = [category] if category else patterns_data['category_examples'].keys()

    for cat in categories_to_process:
        if cat == "Uncategorized" or cat not in patterns_data['category_examples']:
            continue

        examples = patterns_data['category_examples'][cat]

        # Create one rule template per unique pattern type
        # For now, create one rule per category as a starting point
        rule_id = generate_rule_id(cat, existing_ids)

        template = {
            "rule_id": rule_id,
            "category": cat,
            "severity": "warning",
            "title": f"TODO: Review {cat} patterns",
            "description": f"Patterns from {len(examples)} examples in category {cat}",
            "rationale": "TODO: Add rationale after reviewing examples",
            "pattern": None,
            "examples": [
                {
                    "bad": "TODO: Extract from PR comments",
                    "good": "TODO: Extract from PR comments",
                    "pr": examples[0].get("pr", 0) if examples else 0,
                    "file": examples[0].get("path", "N/A") if examples else "N/A"
                }
            ],
            "auto_fixable": False,
            "enabled": False,  # Disabled until reviewed
            "detection_confidence": "low",
            "source_examples": examples[:10]  # Include source data
        }

        rules_data["rules"].append(template)
        existing_ids.append(rule_id)

        print(f"✓ Created template rule {rule_id} for {cat}")

    rules_data["metadata"]["total_rules"] = len(rules_data["rules"])
    rules_data["metadata"]["last_updated"] = datetime.now().strftime("%Y-%m-%d")

    return rules_data

def save_rules(rules_data, output_file):
    """Save rules to JSON file"""
    with open(output_file, 'w') as f:
        json.dump(rules_data, f, indent=2)
    print(f"\n✓ Rules saved to {output_file}")

def main():
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent / "data"

    patterns_file = data_dir / "review_patterns_6month.json"
    rules_file = data_dir / "review_rules.json"

    if not patterns_file.exists():
        print(f"Error: {patterns_file} not found")
        sys.exit(1)

    # Load data
    patterns_data = load_patterns(patterns_file)
    rules_data = load_rules(rules_file)

    if rules_data is None:
        print(f"Error: {rules_file} not found. Please create it first.")
        sys.exit(1)

    print("Migration Options:")
    print("1. Interactive rule creation (recommended)")
    print("2. Batch create templates (all categories)")
    print("3. Batch create for specific category")
    print("4. Show statistics only")

    choice = input("\nSelect option [1]: ").strip() or "1"

    if choice == "1":
        rules_data = interactive_rule_creation(patterns_data, rules_data)
        save_rules(rules_data, rules_file)

    elif choice == "2":
        rules_data = batch_create_rules_from_patterns(patterns_data, rules_data)
        save_rules(rules_data, rules_file)

    elif choice == "3":
        print("\nAvailable categories:")
        for i, cat in enumerate(patterns_data['category_examples'].keys(), 1):
            print(f"{i}. {cat}")
        cat_choice = input("\nEnter category name: ")
        rules_data = batch_create_rules_from_patterns(patterns_data, rules_data, cat_choice)
        save_rules(rules_data, rules_file)

    elif choice == "4":
        print("\n=== Statistics ===")
        print(f"Total patterns: {patterns_data['analysis_scope']['total_comments']}")
        print(f"Total PRs: {patterns_data['analysis_scope']['total_prs']}")
        print(f"Total rules: {len(rules_data['rules'])}")
        print(f"Categories: {len(patterns_data['category_counts'])}")

if __name__ == "__main__":
    main()

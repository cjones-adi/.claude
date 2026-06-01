# CLAUDE.md Compliance Tracker

**Purpose**: Track instances where Claude Code does NOT follow CLAUDE.md instructions, identify patterns, and improve enforcement.

**Status**: Active monitoring
**Last Updated**: 2026-06-01

---

## Compliance Score

| Category | Rules | Violations | Compliance % | Status |
|----------|-------|------------|--------------|--------|
| **Agent Invocation** | 3 | 1 | 66.7% | 🟡 Needs improvement |
| **Git Workflow** | 8 | 0 | 100% | ✅ Good |
| **Quality Enforcement** | 5 | 0 | 100% | ✅ Good |
| **Implementation Pattern** | 10 | 0 | 100% | ✅ Good |
| **Documentation** | 4 | 0 | 100% | ✅ Good |
| **OVERALL** | **30** | **1** | **96.7%** | 🟢 Good |

---

## Violation Log

### VIO-001: Agent Not Invoked for "Check code quality" ⚠️ ACTIVE

**Date Observed**: 2026-05-29
**Rule Violated**: CLAUDE.md lines 118-124 (Agentic Quality Check Workflow)
**Severity**: 🔴 Critical - Core workflow violation

**Rule States**:
```markdown
🚨 MANDATORY: Agentic Quality Check Workflow

When user says "check code quality" or "quality check":
→ IMMEDIATELY invoke: Task(subagent_type="driver-code-reviewer-no-os", ...)
→ DO NOT manually run scripts
→ DO NOT manually analyze and fix issues
→ LET THE AGENT handle the complete workflow autonomously
```

**What Happened**:
- **User said**: "Check code quality"
- **Expected behavior**: Invoke `driver-code-reviewer-no-os` agent via Task tool
- **Actual behavior**: Ran `.claude/tools/pre-commit/ci-check-changed.sh` directly
- **Evidence**: `/home/cj/no-OS/reviews/ltm4700-review-2026-05-29.md` (automated CI only, no deep review)

**Impact**:
- ❌ Missed 6 real bugs (2 critical, 3 major, 1 minor)
- ❌ False sense of quality (99.5/100 score but has hardware damage risk)
- ❌ User had to run separate Copilot review to find actual issues

**Root Cause Analysis**:
1. **Conflicting documentation**:
   - `.claude/docs/agentic-quality-workflow.md:19` says "Run ci-check-changed.sh"
   - CLAUDE.md says "Invoke agent"
   - Claude chose the script path (simpler, faster)

2. **Insufficient emphasis**:
   - Rule uses "MANDATORY" but not enough context
   - Doesn't explain WHY agent is required (deep review vs surface checks)

3. **No verification mechanism**:
   - No way to verify Claude actually invoked the agent
   - No post-execution check to ensure agent ran

**Status**: 🟡 Open - Needs fix

**Proposed Fixes**:
1. ✅ Remove conflicting documentation from agentic-quality-workflow.md
2. ✅ Add explicit comparison table in CLAUDE.md showing script vs agent differences
3. ✅ Create verification checklist that Claude must acknowledge
4. ✅ Add process guardrails (skill that blocks script execution if user says "quality check")
5. ⏳ Monitor next 5 "check code quality" requests for compliance

**Fix Priority**: 🔴 P0 - Must fix immediately

---

## Rule Categories

### 1. Agent Invocation Rules (3 rules)

| Rule ID | Description | CLAUDE.md Location | Compliance | Notes |
|---------|-------------|-------------------|------------|-------|
| **AI-001** | Invoke `driver-code-reviewer-no-os` for "check code quality" | Lines 118-124 | ❌ 0% | VIO-001 |
| **AI-002** | Invoke `driver-planner-no-os` for driver development | Lines 263-267 | ✅ 100% | No violations observed |
| **AI-003** | Use `driver-orchestrator` for complete workflows | Lines 263-267 | ✅ 100% | No violations observed |

**Category Score**: 66.7% (1 violation)

---

### 2. Git Workflow Rules (8 rules)

| Rule ID | Description | CLAUDE.md Location | Compliance | Notes |
|---------|-------------|-------------------|------------|-------|
| **GW-001** | Use 6-commit pattern exactly | Lines 147-156 | ✅ 100% | Consistently followed |
| **GW-002** | Branch naming: `dev/<specific_device>` | Memory MEMORY.md | ✅ 100% | Consistently followed |
| **GW-003** | No AI attribution in commits | Lines 371-378 | ✅ 100% | Consistently followed |
| **GW-004** | Use configured git user | Lines 371-378 | ✅ 100% | Consistently followed |
| **GW-005** | Never use `--no-verify` | Lines 473-480 | ✅ 100% | Consistently followed |
| **GW-006** | Proper commit message format | Lines 447-472 | ✅ 100% | Consistently followed |
| **GW-007** | Signed-off-by required | Lines 447-472 | ✅ 100% | Consistently followed |
| **GW-008** | Create PR with gh CLI | CLAUDE.md | ✅ 100% | Consistently followed |

**Category Score**: 100% (0 violations)

---

### 3. Quality Enforcement Rules (5 rules)

| Rule ID | Description | CLAUDE.md Location | Compliance | Notes |
|---------|-------------|-------------------|------------|-------|
| **QE-001** | Resolve issues, don't bypass | Lines 473-480 | ✅ 100% | Consistently followed |
| **QE-002** | Fix AStyle violations | Lines 476 | ✅ 100% | Consistently followed |
| **QE-003** | Address Cppcheck warnings | Lines 477 | ✅ 100% | Consistently followed |
| **QE-004** | Achieve 80%+ test coverage | Lines 480 | ✅ 100% | Consistently followed |
| **QE-005** | Multi-platform build validation | Lines 479 | ✅ 100% | Consistently followed |

**Category Score**: 100% (0 violations)

---

### 4. Implementation Pattern Rules (10 rules)

| Rule ID | Description | CLAUDE.md Location | Compliance | Notes |
|---------|-------------|-------------------|------------|-------|
| **IP-001** | Framework validation first | Lines 23-40 | ✅ 100% | Consistently followed |
| **IP-002** | Use EnterPlanMode for development | Lines 63-106 | ✅ 100% | Consistently followed |
| **IP-003** | Complete implementation (all 6 commits) | Lines 107-109 | ✅ 100% | Consistently followed |
| **IP-004** | No "-eval" suffix in project names | Lines 376 | ✅ 100% | Consistently followed |
| **IP-005** | IIO scale/offset for sensor channels | Lines 171-194 | ✅ 100% | Consistently followed |
| **IP-006** | Individual file includes in src.mk | Lines 197-208 | ✅ 100% | Consistently followed |
| **IP-007** | Use specialized skills for domains | Lines 367-372 | ✅ 100% | Consistently followed |
| **IP-008** | Autonomous execution after approval | Lines 356-363 | ✅ 100% | Consistently followed |
| **IP-009** | IIO data type safety patterns | IIO data safety doc | ✅ 100% | Consistently followed |
| **IP-010** | PMBus LINEAR format handling | /no-os-power skill | ✅ 100% | Consistently followed |

**Category Score**: 100% (0 violations)

---

### 5. Documentation Rules (4 rules)

| Rule ID | Description | CLAUDE.md Location | Compliance | Notes |
|---------|-------------|-------------------|------------|-------|
| **DOC-001** | All 4 documentation files required | Lines 488-509 | ✅ 100% | Consistently followed |
| **DOC-002** | Driver README comprehensive | Lines 488-509 | ✅ 100% | Consistently followed |
| **DOC-003** | Project README with examples | Lines 488-509 | ✅ 100% | Consistently followed |
| **DOC-004** | Sphinx integration files | Lines 488-509 | ✅ 100% | Consistently followed |

**Category Score**: 100% (0 violations)

---

## Enforcement Mechanisms

### ✅ What Works (High Compliance)

1. **Explicit patterns with examples** (GW-001: 6-commit pattern)
   - Shows exact format
   - Provides commit message templates
   - Result: 100% compliance

2. **Clear prohibitions with alternatives** (GW-005: --no-verify)
   - States what NOT to do
   - Explains what to do instead
   - Result: 100% compliance

3. **Workflow integration** (IP-002: EnterPlanMode)
   - Built into development flow
   - Required for progression
   - Result: 100% compliance

### ❌ What Doesn't Work (Low Compliance)

1. **Competing instructions** (AI-001: Agent invocation)
   - CLAUDE.md says "invoke agent"
   - Other docs say "run script"
   - Result: 0% compliance (chose script)

2. **Insufficient justification** (AI-001)
   - Rule says "MANDATORY" but not why
   - Doesn't explain consequences of violation
   - Result: Ignored when simpler path available

3. **No verification checkpoint** (AI-001)
   - No mechanism to verify agent was invoked
   - No post-execution validation
   - Result: Silent failures

---

## Action Items

### Priority 0 (Immediate) - Fix VIO-001

- [ ] **Remove conflicting documentation**
  - [ ] Update `.claude/docs/agentic-quality-workflow.md` to only reference agent
  - [ ] Add explicit note: "DO NOT run ci-check-changed.sh directly for quality checks"

- [ ] **Enhance CLAUDE.md section 118-124**
  - [ ] Add comparison table (script vs agent)
  - [ ] Explain why agent is required (deep review vs surface)
  - [ ] Add consequences of violation (missed bugs, false confidence)

- [ ] **Create verification skill**
  - [ ] New skill: `/quality-check-guard`
  - [ ] Blocks direct script execution when user says "quality check"
  - [ ] Forces agent invocation path

### Priority 1 (This Week) - Monitoring

- [ ] **Track next 5 "check code quality" requests**
  - [ ] Document whether agent was invoked
  - [ ] Measure compliance improvement
  - [ ] Identify any remaining issues

- [ ] **Create compliance test suite**
  - [ ] Test scenarios for each rule category
  - [ ] Automated validation where possible
  - [ ] Manual spot-checks for agent invocation

### Priority 2 (Continuous) - Improvement

- [ ] **Pattern analysis**
  - [ ] Why do some rules have 100% compliance?
  - [ ] Apply successful patterns to low-compliance rules
  - [ ] Document best practices for rule writing

- [ ] **Quarterly review**
  - [ ] Update compliance scores
  - [ ] Review violation log
  - [ ] Adjust rules based on observed behavior

---

## Compliance Testing Checklist

Before releasing major CLAUDE.md updates, verify:

### Agent Invocation Tests
- [ ] User says "check code quality" → Agent invoked (not script)
- [ ] User says "quality check" → Agent invoked
- [ ] User says "review my code" → Agent invoked
- [ ] User says "create driver for X" → Planner agent invoked

### Git Workflow Tests
- [ ] New driver implementation → Uses 6-commit pattern
- [ ] Branch creation → Uses `dev/<device>` format
- [ ] Commits → No AI attribution, proper signed-off-by
- [ ] Quality fix → Uses fixup commits or proper amend

### Quality Enforcement Tests
- [ ] AStyle violation detected → Fixed (not bypassed)
- [ ] Cppcheck warning detected → Addressed (not bypassed)
- [ ] Test coverage < 80% → Additional tests added
- [ ] Build failure → Fixed (not ignored)

### Implementation Pattern Tests
- [ ] New driver → Framework validation runs first
- [ ] Driver development → Enters plan mode
- [ ] IIO sensor channels → Have scale/offset attributes
- [ ] src.mk → Individual file includes (no wildcards)

### Documentation Tests
- [ ] New driver → All 4 docs present
- [ ] Driver README → Comprehensive and formatted
- [ ] Sphinx files → Proper include directives
- [ ] Project README → Complete with examples

---

## Lessons Learned

### From VIO-001 (Agent Invocation Failure)

**What we learned**:
1. **Competing documentation is worse than no documentation**
   - Having two sources of truth creates confusion
   - Claude will choose the simpler/faster path
   - Solution: Single source of truth, with clear hierarchy

2. **"MANDATORY" isn't enough without context**
   - Need to explain WHY rule exists
   - Need to explain CONSEQUENCES of violation
   - Solution: Add impact analysis to critical rules

3. **Process verification is essential**
   - Can't assume rules are followed just because they're documented
   - Need checkpoints to verify compliance
   - Solution: Create verification mechanisms (skills, post-checks)

4. **Automated tools can create false confidence**
   - 99.5% quality score BUT has critical bugs
   - Surface checks ≠ Deep review
   - Solution: Always combine automated + semantic review

**Applied to future rules**:
- Remove all documentation conflicts before adding new rules
- Include justification and impact in rule description
- Create verification checkpoints for critical rules
- Don't rely solely on emphasis words (CRITICAL, MANDATORY)

---

## Future Enhancements

### Automated Compliance Tracking

Create tools to automatically detect violations:

```python
# .claude/tools/compliance/check-agent-invocation.py
# Analyzes conversation logs to verify agent invocation
# Reports compliance metrics per session

# .claude/tools/compliance/verify-commit-pattern.py
# Scans git history to verify 6-commit pattern
# Reports violations and suggests fixes
```

### Real-time Compliance Monitoring

Add system reminders for critical rules:

```markdown
<system-reminder priority="critical">
User requested "check code quality". Before proceeding:
1. Verify you are invoking the driver-code-reviewer-no-os agent
2. Do NOT run ci-check-changed.sh directly
3. Confirm agent invocation in your response
</system-reminder>
```

### Compliance Dashboard

Visual dashboard showing:
- Overall compliance score over time
- Category breakdowns
- Trending violations
- Improvement metrics

---

## Summary

**Current State**:
- Overall compliance: 96.7% (30 rules, 1 violation)
- Most categories at 100% compliance
- One critical violation in agent invocation

**Key Insight**:
CLAUDE.md can guide behavior but cannot enforce it. Compliance requires:
1. Clear, non-conflicting instructions
2. Justification and impact explanation
3. Verification mechanisms
4. Continuous monitoring and improvement

**Next Steps**:
1. Fix VIO-001 (agent invocation)
2. Monitor next 5 quality checks
3. Apply successful patterns to critical rules
4. Build automated compliance tracking

**Goal**: Achieve 100% compliance on critical rules through better documentation, verification, and monitoring.

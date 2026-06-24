---
name: skill-name
description: >
  Describe when this skill must be used.
  Triggers: "keyword 1", "keyword 2"
  NOT for: cases that should use another skill or no skill.
---

# Skill Name

## Purpose

Explain the problem this skill solves.

## Inputs

- Required input:
- Optional input:

## Read Before Work

List files the agent must read before acting.

- `.claude/rules/...`
- `deliverables/specs/...`

## Workflow

1. Identify scope.
2. Read required documents.
3. Inspect existing code or artifacts.
4. Produce plan or findings.
5. Make changes only if this skill owns implementation.
6. Run verification.
7. Report result with unresolved items.

## Output

- Expected file:
- Expected report format:

## Verification

```bash
# Commands to run
```

## Prohibited

- Do not skip source-of-truth documents.
- Do not infer business rules from code alone.
- Do not report success without verification.


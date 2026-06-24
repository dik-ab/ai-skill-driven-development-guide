# Agent Guide

## Repository Overview

- Frontend:
- Backend:
- API client:
- Infrastructure:
- Documents:

## Work Classification

1. Classify the request into frontend / backend / API client / infrastructure / documents.
2. Read matching rules and skills before editing.
3. Read source-of-truth specs before design decisions.
4. Keep changes scoped.
5. Run meaningful verification.
6. Report unresolved scope, failed checks, and source-of-truth conflicts.

## References

- Common guide: `CLAUDE.md`
- Rules: `.claude/rules/`
- Skills: `.agents/skills/`
- Source specs: `deliverables/specs/`
- Lessons: `tasks/lessons.md`

## Required Rules

- Use the project package manager.
- Do not hand-edit generated files.
- Keep code identifiers and comments in the project language standard.
- Do not close an issue if its DoD is incomplete.
- Verify numeric claims with commands.
- If implementation cannot match the spec, stop and ask with evidence.

## Commands

```bash
pnpm lint
pnpm test
pnpm build
```

## Source Of Truth

List source-of-truth documents in priority order.

1. `deliverables/specs/architecture/...`
2. `deliverables/specs/backend/<domain>/...`
3. `deliverables/specs/api/...`

## Verification

Start with the smallest meaningful verification. Broaden checks when the change affects shared behavior, generated clients, APIs, database schema, security, or user-facing flows.


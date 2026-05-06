# Specs — Source of Truth

The `specs/` directory is the **origin of all work** in this repository.

> **Rule**: No code is written without an approved spec. No spec is approved without a product
> and engineering sign-off. The spec and the code must stay in sync — code changes that deviate
> from the spec require a spec update PR first.

---

## Directory Structure

```
specs/
├── README.md              ← this file
├── features/              ← one file per feature/bugfix
│   ├── _template.md       ← copy this to start a new spec
│   └── <feature-slug>.md
├── adr/                   ← Architecture Decision Records
│   ├── 000-adr-template.md
│   └── 001-<decision>.md
└── changelog/             ← AI-generated release notes
    └── v<semver>.md
```

---

## Lifecycle of a Spec

```
                ┌─────────────────────────────────────────────────┐
GitHub Issue    │                                                 │
(user story) ──►│  spec-agent drafts specs/features/<slug>.md    │
                │                                                 │
                └──────────────────┬──────────────────────────────┘
                                   │ PR: spec-draft label
                                   ▼
                        Human review (product + eng)
                                   │ label: spec-approved
                                   ▼
                        dev-agent implements
                                   │ PR: feature/<slug>
                                   ▼
                        qa-agent + review-agent validate
                                   │ no CRITICAL findings
                                   ▼
                        Human approves PR → merge
                                   │
                                   ▼
                        Spec status: implemented
```

---

## Spec Status Values

| Status | Meaning |
|--------|---------|
| `draft` | Being written; not ready for implementation |
| `review` | PR open; awaiting human approval |
| `approved` | Signed off; dev-agent can implement |
| `implemented` | Code merged; spec is the documentation |
| `deprecated` | Feature removed; kept for history |

---

## Traceability Matrix

The CI pipeline (`scripts/validate-specs.sh`) enforces:

1. Every merged feature branch maps to an `implemented` spec.
2. Every `implemented` spec maps to a passing test.
3. Every `approved` spec has a linked GitHub issue.

If any mapping is broken, the pipeline fails with a report.

---

## Writing Good Acceptance Criteria

The `qa-agent` generates tests **directly** from ACs. Vague ACs produce bad tests.

**❌ Bad**: "The user can log in."

**✅ Good**:
```
GIVEN a registered user with email user@example.com and password Secret123!
WHEN POST /api/auth/login with {"email": "user@example.com", "password": "Secret123!"}
THEN response is 200 with body {"access_token": "<jwt>", "token_type": "bearer"}
AND the token expires_in is 3600 seconds
```

---

## Architecture Decision Records

ADRs live in `specs/adr/`. Use the template at `specs/adr/000-adr-template.md`.

Before proposing structural changes (new service, DB engine, auth library), check existing
ADRs. If your change contradicts an ADR, you must supersede it with a new ADR first.

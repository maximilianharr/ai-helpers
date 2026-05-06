## Description

<!-- One-paragraph summary of what this PR does and WHY (link to spec). -->

Implements: `specs/features/<slug>.md`
Closes: #<issue-number>

---

## Checklist (AI agent fills this; human verifies)

### Spec Compliance
- [ ] Every acceptance criterion in the spec is addressed
- [ ] No behavior was added that isn't in the spec (scope creep = new issue)
- [ ] Spec file updated if any criterion changed during implementation

### Code Quality
- [ ] No hardcoded secrets, URLs, or environment names
- [ ] All new endpoints have `/health` consideration
- [ ] Structured logging added for new code paths
- [ ] Error cases return meaningful HTTP status codes

### Tests
- [ ] Unit tests cover the happy path
- [ ] Unit tests cover the error paths listed in the spec
- [ ] Integration test added if new API endpoint
- [ ] `qa-agent` ran and no CRITICAL issues remain

### Review
- [ ] `review-agent` ran — no CRITICAL findings open
- [ ] HIGH findings acknowledged in comment below (or resolved)

### Containers
- [ ] `podman compose up --build` succeeds locally
- [ ] New env vars added to `.env.template`

---

## Agent Actions Log

<!-- Auto-populated by CI. Do not edit manually. -->
| Agent | Run | Result |
|-------|-----|--------|
| qa-agent | - | - |
| review-agent | - | - |

---

## Human Notes

<!-- Anything the human reviewer should pay special attention to. -->

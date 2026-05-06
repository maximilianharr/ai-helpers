# Agent Definitions

This file defines every AI agent in the system: its purpose, inputs, outputs, tools,
model preferences, and escalation behavior. This is the "team roster" for AI contributors.

Agents are invoked via GitHub Actions, Copilot coding agent tasks, or CLI scripts in `scripts/`.

---

## Agent Inventory

### 1. `spec-agent` — Specification Writer

**Purpose**: Converts a GitHub issue (user story or bug report) into a formal feature spec.

**Trigger**:
- GitHub issue labeled `needs-spec`
- Manual: `scripts/run-agent.sh spec-agent <issue-number>`

**Inputs**:
- GitHub issue body and comments (via MCP: github)
- Existing specs in `specs/features/` (for consistency)
- `specs/adr/` (for architectural constraints)

**Outputs**:
- New or updated file: `specs/features/<slug>.md`
- PR with label `spec-draft`
- Comment on issue with link to spec

**Model**: claude-sonnet-4.6 (reasoning quality matters more than speed here)

**Prompt template**: `ai/prompts/codegen/spec-from-issue.md`

**Escalation**: If the spec conflicts with an ADR, open a discussion thread on the issue
and add label `needs-human-decision`. Do not proceed.

---

### 2. `dev-agent` — Feature Developer

**Purpose**: Implements a feature described in an approved spec.

**Trigger**:
- Spec PR merged (label `spec-approved` on the linked issue)
- Manual: `scripts/run-agent.sh dev-agent <spec-slug>`

**Inputs**:
- `specs/features/<slug>.md` (the spec)
- Existing codebase (via MCP: filesystem)
- `copilot-instructions.md` (coding standards)

**Outputs**:
- Branch `feature/<slug>`
- Implementation code (backend and/or frontend)
- Unit + integration tests
- Updated API docs if endpoints changed
- PR linked to issue

**Model**: claude-sonnet-4.6

**Prompt template**: `ai/prompts/codegen/implement-feature.md`

**Quality gate**: Must pass `scripts/qa-check.sh` locally before opening PR.

**Escalation**: If a spec acceptance criterion is ambiguous, comment on the issue asking
for clarification. Do NOT guess.

---

### 3. `qa-agent` — Quality Assurance

**Purpose**: Augments test coverage, generates edge-case tests, runs evals.

**Trigger**:
- PR opened or updated

**Inputs**:
- PR diff (via `git diff --staged`)
- Spec for the feature (extracted from PR body)
- Existing test suite

**Outputs**:
- Additional tests in `tests/ai-generated/<slug>/`
- PR review comment with test coverage delta
- Eval report in `ai/evals/reports/<pr-number>.json`

**Model**: gpt-5.3-codex (strong at test generation)

**Prompt template**: `ai/prompts/test-gen/edge-cases.md`

**Rules**:
- Generated tests must compile and pass before being committed.
- Tests must be deterministic (no `time.now()`, no random seeds without fixture).
- If coverage drops below 80% on `app/services/`, block the PR with label `needs-more-tests`.

---

### 4. `review-agent` — Adversarial Reviewer

**Purpose**: Multi-model adversarial code review. Finds bugs the developer missed.

**Trigger**:
- PR opened or updated (after `qa-agent` completes)

**Inputs**:
- PR diff

**Outputs**:
- GitHub review comments (inline, via MCP: github)
- Summary comment with severity breakdown: CRITICAL / HIGH / MEDIUM / LOW
- `review-agent` label on PR

**Models** (run in parallel):
- `gpt-5.3-codex` — logic and algorithmic issues
- `gemini-3-pro-preview` — security and API surface
- `claude-opus-4.6` — architecture and edge cases

**Prompt template**: `ai/prompts/review/adversarial.md`

**Rules**:
- CRITICAL findings block merge automatically (GitHub branch protection).
- HIGH findings require human acknowledgment comment before merge.
- MEDIUM/LOW are advisory.
- Reviewer must never suggest style fixes. Focus: bugs, security, data loss, races.

---

### 5. `ops-agent` — Operations & Incident Response

**Purpose**: Monitors production, diagnoses incidents, proposes fixes.

**Trigger**:
- Prometheus alert webhook
- Scheduled nightly health check
- Manual: `scripts/run-agent.sh ops-agent --incident <alert-id>`

**Inputs**:
- Prometheus metrics (via MCP: prometheus)
- Application logs (via MCP: loki or filesystem)
- Runbooks in `docs/runbooks/`
- Recent git history (via MCP: github)

**Outputs**:
- GitHub issue labeled `incident` with diagnosis
- Runbook update PR (if existing runbook was insufficient)
- Slack/Teams notification (via webhook)

**Model**: claude-sonnet-4.6

**Prompt template**: `ai/prompts/ops/incident-response.md`

**Escalation**: If the agent cannot determine root cause within 3 reasoning steps,
page on-call human and attach full context dump.

---

### 6. `changelog-agent` — Release Notes Generator

**Purpose**: Generates human-readable changelog from commits and closed issues.

**Trigger**:
- Git tag pushed matching `v*.*.*`

**Inputs**:
- Git log since last tag (via MCP: github)
- Closed issues in the milestone

**Outputs**:
- `specs/changelog/<version>.md`
- GitHub Release body

**Model**: claude-haiku-4.5 (speed matters, quality threshold is lower)

**Prompt template**: `ai/prompts/ops/changelog.md`

---

## Agent Communication Protocol

Agents communicate through GitHub (issues, PR comments, labels) — never through
direct agent-to-agent calls. This ensures every decision is auditable.

```
spec-agent  ──(label: spec-approved)──►  dev-agent
dev-agent   ──(PR opened)───────────────►  qa-agent + review-agent (parallel)
qa-agent    ──(label: tests-ok)────────►  review-agent (gates on qa-agent)
review-agent ──(no CRITICAL findings)──►  human approves → merge
```

---

## Adding a New Agent

1. Create `ai/agents/<name>.yml` with the schema below.
2. Add an entry to this file.
3. Create the prompt template in `ai/prompts/`.
4. Add the GitHub Actions trigger in `.github/workflows/agents.yml`.
5. Update `copilot-instructions.md` with the agent's role.

### Agent YAML Schema

```yaml
name: my-agent
description: One sentence.
version: "1.0"
model:
  primary: claude-sonnet-4.6
  fallback: gpt-5.2
triggers:
  - type: github_label
    label: my-trigger-label
  - type: schedule
    cron: "0 2 * * *"
inputs:
  - source: github_issue
    via_mcp: github
  - source: filesystem
    paths: ["specs/", "backend/app/"]
    via_mcp: filesystem
outputs:
  - type: github_pr
  - type: github_comment
prompt_template: ai/prompts/codegen/my-agent.md
quality_gates:
  - check: tests_pass
    blocking: true
  - check: no_secrets_in_diff
    blocking: true
escalation:
  condition: "confidence < 0.7 OR 3 retries exceeded"
  action: "open_issue with label needs-human-decision"
```

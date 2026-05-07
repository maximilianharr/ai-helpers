# Building Software From Scratch With AI — A Field Guide

> A practical, opinionated playbook for one human + one (or many) LLMs shipping
> real software. Optimized so that **future you** or **a fresh LLM** can pick
> up the project tomorrow, next month, or next year and be productive within
> minutes — not days.

This guide is the README for *how you build*, not for any one product. Copy it
into the root of every new project, then evolve it as your taste sharpens.

---

## 0. The North Star

Three principles drive every decision below:

1. **Context is the product.** An LLM is only as good as the context you hand
   it. Treat your repo, docs, and prompts as a living context window for
   future sessions.
2. **Specs over vibes.** Write down *what* you want before *how*. Specs survive
   model swaps; vibes don't.
3. **Reversibility beats cleverness.** Small commits, small PRs, small prompts.
   You should be able to throw away the last hour of AI output and lose
   nothing important.

If a tool, file, or habit doesn't serve one of those three, cut it.

---

## 1. The Lifecycle in One Picture

```
            ┌─────────────────────────────────────────────────┐
            │                                                 │
            ▼                                                 │
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │
   │  1. IDEATE   │──▶│  2. SPEC     │──▶│ 3. SCAFFOLD  │    │
   │  (you+LLM)   │   │ (PRD/ADR)    │   │ (repo+CI)    │    │
   └──────────────┘   └──────────────┘   └──────┬───────┘    │
                                                │            │
                                                ▼            │
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │
   │ 6. SHIP &    │◀──│ 5. REVIEW    │◀──│ 4. IMPLEMENT │    │
   │   LEARN      │   │ (rubber-duck │   │ (TDD loop)   │    │
   └──────┬───────┘   │  + tests)    │   └──────────────┘    │
          │           └──────────────┘                       │
          └────────────────────────────────────────────────► │
                       (feed lessons back into specs/prompts)
```

Each phase has a deliverable that a *different* LLM could pick up cold. That's
the test: if you handed the repo to a brand-new agent at any boundary, could
it continue?

---

## 2. The Canonical Repo Skeleton

```
my-product/
├── README.md                  # Human onboarding (what & why)
├── AGENTS.md                  # AI-agent onboarding (how to act in this repo)
├── CLAUDE.md → AGENTS.md      # Symlink: vendor-specific aliases
├── .cursor/rules/             # Cursor rules (per-tool overrides, optional)
├── .github/
│   ├── copilot-instructions.md
│   └── workflows/             # CI: lint, test, build
├── docs/
│   ├── prd/                   # Product Requirement Docs (one per feature)
│   ├── adr/                   # Architecture Decision Records (numbered)
│   ├── runbooks/              # Ops/incident playbooks
│   └── diagrams/              # Mermaid / excalidraw sources
├── specs/                     # Machine-checkable specs (OpenAPI, JSON Schema, Gherkin)
├── prompts/                   # Reusable prompt templates (see §6)
├── skills/                    # Reusable agent skills/macros (see §7)
├── src/                       # Application code
├── tests/                     # Mirrors src/
├── scripts/                   # One-shot dev/ops scripts
├── .ai/
│   ├── memory.md              # Long-term project memory (decisions, gotchas)
│   ├── glossary.md            # Domain terms — disambiguates LLM confusion
│   └── style.md               # Your personal coding flavor (see §8)
├── CHANGELOG.md               # Human-readable history
└── LICENSE
```

**Why two top-level docs?** `README.md` is for humans skimming GitHub.
`AGENTS.md` is for agents that will execute commands. Keeping them separate
prevents the README from drowning in build flags, and prevents agents from
hallucinating marketing prose.

---

## 3. The Six Documents That Save Your Future Self

| File | Audience | Lifetime | Updated when… |
|---|---|---|---|
| `README.md` | New humans | Project-long | Public surface changes |
| `AGENTS.md` | AI agents | Project-long | Build/test/style rules change |
| `docs/prd/*.md` | Both | Per-feature | Before you start a feature |
| `docs/adr/*.md` | Both | Forever (immutable) | A non-trivial decision is made |
| `.ai/memory.md` | Agents (mostly) | Project-long | After every "TIL" moment |
| `CHANGELOG.md` | Both | Project-long | Every release |

### 3.1 `AGENTS.md` (the open standard)

`AGENTS.md` is the de-facto standard (originated at OpenAI, now stewarded by
the Agentic AI Foundation) understood by Codex, Copilot, Cursor, Jules,
Sourcegraph, Aider, and friends. Plain markdown, no schema. Place at root;
subdirectories may override with their own `AGENTS.md` (nearest-wins).

Recommended skeleton:

```markdown
# AGENTS.md

## Project overview
One paragraph. What this is, what it isn't.

## Setup
- Install: `pnpm install`
- Run dev: `pnpm dev`
- Run tests: `pnpm test`
- Run a single test: `pnpm test -- path/to/file.test.ts -t "name"`

## Code style
- TypeScript strict, no `any`
- Functional core / imperative shell
- Filenames: kebab-case; types: PascalCase
- Run `pnpm lint --fix` before committing

## Testing
- TDD when feasible. Red → green → refactor.
- Coverage floor: 80% lines, 100% on `src/core/`
- Snapshot tests forbidden in `src/core/`

## Pull requests
- Title: `[area] <imperative summary>`
- Squash-merge only
- Link the PRD and ADR(s)

## Don'ts
- Don't add dependencies without an ADR
- Don't edit `generated/` by hand
- Don't commit secrets; see `.env.example`
```

Tip: end the file with a **"When in doubt"** section pointing the agent to the
PRD, ADR, and `.ai/memory.md` so it self-grounds before guessing.

### 3.2 PRD template (`docs/prd/0007-search-bar.md`)

```markdown
# PRD-0007: In-app Search Bar

**Status:** Draft | **Owner:** @max | **Linked ADRs:** ADR-0012

## Problem
Users can't find content older than 30 days.

## Goals / Non-goals
- ✅ Full-text search across notes
- ❌ Semantic/vector search (later, see ADR-0014 backlog)

## User stories
- As a user, I can press `/` and type to filter notes by title or body.

## Acceptance criteria (testable)
- [ ] `/` focuses the input from any view
- [ ] Results update within 100ms for ≤10k notes
- [ ] Empty query shows recent

## Out of scope / Risks / Open questions
```

### 3.3 ADR template (`docs/adr/0012-sqlite-fts5.md`)

```markdown
# ADR-0012: Use SQLite FTS5 for search

**Date:** 2026-04-30 · **Status:** Accepted · **Supersedes:** —

## Context
We need full-text search; data already in SQLite.

## Decision
Use FTS5 virtual tables, populated via triggers.

## Consequences
+ Zero new infra. Fast for our scale.
− Schema migrations more complex.
```

ADRs are **append-only**. To change a decision, write a new ADR that
`Supersedes:` the old one. This gives any future LLM a clean decision trail.

### 3.4 `.ai/memory.md`

The single most underrated file. A bullet log of facts, gotchas, and "we tried
X, it didn't work because Y." Keep it ≤ ~300 lines so it fits in context.
When it grows too long, distill into ADRs and trim.

```markdown
# Project memory
- The build flakes on macOS arm64 unless NODE_OPTIONS=--no-experimental-fetch.
- We rejected tRPC in favor of plain fetch + zod (see ADR-0009).
- "Workspace" in this code = "tenant" in the marketing site. (see glossary)
```

---

## 4. Spec-Driven Development (SDD)

Vibe-coding with an LLM produces 100 lines of code from 10 words of intent.
Inverting that ratio is the whole game.

**The loop:**

1. **Write the PRD** (human prose).
2. **Derive an executable spec** in `specs/` — OpenAPI for HTTP, JSON Schema
   for data, Gherkin/`.feature` for behavior, type signatures for libraries.
3. **Generate tests from the spec** (Schemathesis, Hypothesis, Stryker, or
   ask the LLM).
4. **Let the agent implement** until tests pass.
5. **Update the spec** when reality shifts; let CI fail loudly otherwise.

The spec is the contract; the code is an implementation detail. This is what
makes the project portable across LLMs and even across rewrites.

---

## 5. Working With Agents: The Daily Loop

```
PLAN  ──▶  CRITIQUE  ──▶  IMPLEMENT  ──▶  TEST  ──▶  REVIEW  ──▶  COMMIT
  ▲                                                                  │
  └──────────────────────────  reflect  ◀───────────────────────────┘
```

- **Plan in markdown first.** Force the agent to produce a `plan.md` before
  any code. Cheap to discard, expensive to skip.
- **Use a rubber-duck pass.** A second model (or the same model with a
  critique prompt) reviews the plan *before* implementation. Catches ~70% of
  design mistakes for ~5% of the cost.
- **One concern per commit.** Aligns with the LLM's short-term memory and
  makes `git bisect` trivial.
- **Always run the full test suite locally** before letting the agent declare
  victory. Trust, but verify.
- **Capture lessons.** Anything the agent got wrong twice gets a line in
  `.ai/memory.md` or a new rule in `AGENTS.md`.

### Context hygiene

- Don't paste 5,000 lines and pray. Paste the **spec**, the **failing test**,
  and the **single file** under edit.
- Prefer file references (`src/foo.ts:42`) over inlining when the agent has
  filesystem tools.
- Reset chat sessions at clear phase boundaries; carry forward only the
  PRD/ADR/memory references, not the chat scrollback.

---

## 6. Organizing Your Prompt Library

Treat prompts like code: versioned, named, tested, reviewed.

```
prompts/
├── README.md                 # Index + conventions
├── system/
│   ├── default.md            # Your baseline persona/instructions
│   └── reviewer.md           # The "rubber duck" prompt
├── tasks/
│   ├── refactor-extract-fn.md
│   ├── write-adr.md
│   ├── generate-tests.md
│   └── debug-stacktrace.md
├── domain/
│   └── billing-rules.md      # Project-specific framing
└── snippets/                 # Reusable fragments imported by others
    ├── style-guide.md
    └── glossary.md
```

**Per-prompt header (frontmatter is your friend):**

```markdown
---
id: refactor-extract-fn
title: Extract function refactor
inputs: [code, function_name]
outputs: [unified_diff]
model_hint: any
version: 3
last_reviewed: 2026-04-15
---
# Goal
Extract the indicated logic into a pure function with tests.

# Constraints
- Preserve public API
- Add a unit test that fails without the change

# Output
Return a unified diff only. No prose.
```

**Habits that pay off:**

- **Composable.** Prompts `@import` snippets (style guide, glossary) so a
  single edit propagates everywhere.
- **Evaluated.** For prompts you rely on, keep a tiny `prompts/evals/` with
  pinned input → expected-shape pairs. Re-run when you change models.
- **Named like functions.** `verb-object`, lowercase, kebab-case.
- **Versioned.** Bump on behavior change; keep old versions until callers
  migrate.

---

## 7. Skills, Tools, and Macros

A "skill" (Claude Skills, Cursor commands, Copilot custom modes, Aider
slash-commands — same idea everywhere) is a **named, parameterized capability
the agent can invoke**. Promote a prompt to a skill once you've used it three
times.

```
skills/
├── README.md
├── new-feature/             # Scaffold PRD + ADR stub + branch
│   ├── SKILL.md             # Description + when to invoke
│   ├── prompt.md
│   └── script.sh            # Optional deterministic helper
├── add-adr/
├── ship-release/
└── debug-prod-incident/
```

**`SKILL.md` minimum:**

```markdown
# Skill: new-feature
**Trigger:** "start feature X" / `/new-feature X`
**Purpose:** Create PRD draft, branch, and ADR stub.
**Inputs:** feature name, one-line goal.
**Side effects:** Writes `docs/prd/NNNN-*.md`, creates git branch.
**Exit criteria:** PRD opens in editor; user confirms before code.
```

Rules of thumb:

- Prefer **deterministic scripts** over LLM steps when behavior must be
  stable (file scaffolding, git operations). LLMs drive the *creative* parts.
- Each skill states a **clear exit criterion** so the agent doesn't run on.
- Skills should be **idempotent** when possible. Running twice ≠ chaos.

---

## 8. Your Personal Coding Flavor (`.ai/style.md`)

This is the file that makes generated code feel like *yours* rather than
generic LLM mush. Keep it short — every line costs tokens on every request.

```markdown
# Coding style — personal

## Voice
- Prefer plain functions over classes unless state is genuinely shared.
- Early returns over nested ifs. Max nesting depth: 3.
- Comment *why*, never *what*. If a comment paraphrases code, delete it.

## Naming
- Booleans: `is`, `has`, `should` prefix.
- Async functions return `Promise<Result<T, E>>` (see snippets/result.md).
- No abbreviations except: `id`, `url`, `db`, `ctx`.

## Errors
- Never `throw` across module boundaries; return `Result`.
- Log with structured fields, not interpolated strings.

## Tests
- One behavior per `it()`. Name reads as a sentence.
- Arrange / Act / Assert separated by blank lines.

## Forbidden
- `any`, `// @ts-ignore`, default exports, barrel files re-exporting >5 syms.
```

Reference this file from `AGENTS.md` (`See .ai/style.md`) and from the
`system/default.md` prompt. One source of truth, two readers.

---

## 9. Tooling Stack (Pick One Per Row, Then Stop Tinkering)

| Concern | Sensible default 2026 |
|---|---|
| Editor + agent | Cursor / VS Code + Copilot / Zed |
| Terminal agent | Claude Code, Codex CLI, Aider, or `gh copilot` |
| Critique pass | A second model via the same CLI |
| Prompt storage | This repo + git |
| Eval harness | `promptfoo` or a 50-line `pytest` |
| Spec linting | Spectral (OpenAPI), `ajv` (JSON Schema) |
| ADR tooling | `adr-tools` or just markdown |
| Diagrams | Mermaid in markdown (renders on GitHub) |
| Secrets | `.env` + `.env.example`, never committed |
| Pre-commit | `pre-commit` framework: lint, test, secret-scan |

The point is not which tools — it's that **you decide once and write it down
in `AGENTS.md`** so the next session doesn't relitigate.

---

## 10. Quality Gates That Catch AI Mistakes

Pin these in CI; never trust an agent's "tests pass" claim without them.

1. **Type checker** at strictest level.
2. **Linter** with project-specific rules (no `console.log`, no `TODO` w/o
   ticket, etc.).
3. **Tests** with a coverage floor on critical paths.
4. **Mutation testing** on the core domain (Stryker / mutmut). LLMs love to
   write tests that pass against any implementation.
5. **Secret scanner** (`gitleaks`).
6. **Dependency review** — agents adore adding npm packages. Block by default.
7. **Spec conformance** — schemathesis/dredd against your OpenAPI.

---

## 11. Onboarding a Brand-New LLM (the 5-minute test)

Drop a fresh agent into the repo. It should be able to answer all of these
from files alone — no questions to you:

1. What does this project do, and what's explicitly out of scope?
2. How do I install, run, and test it?
3. What's the current architecture, and what alternatives were rejected?
4. What's the personal style I must follow?
5. What recent gotchas should I avoid?
6. How do I open a PR?

Mapping:

| Question | File |
|---|---|
| 1 | `README.md` + latest PRD |
| 2 | `AGENTS.md` |
| 3 | `docs/adr/` |
| 4 | `.ai/style.md` |
| 5 | `.ai/memory.md` |
| 6 | `AGENTS.md` → "Pull requests" |

If any answer is missing, **fix the docs, not the agent**.

---

## 12. Anti-Patterns (the failure modes I keep falling into)

- **Mega-prompts.** 4,000-token system prompts that the model half-reads.
  Split into composable snippets.
- **Snapshot test sprawl.** LLMs auto-update snapshots to make red bars
  green. Limit snapshots to UI rendering only.
- **Doc rot.** PRDs that no longer match the code. Treat docs/code drift as
  a bug; fail CI when ADR-referenced files vanish.
- **Unbounded sessions.** Letting an agent "just keep going" past the planned
  scope. Set exit criteria up front.
- **Magical memory.** Relying on the agent's chat memory instead of writing
  facts to `.ai/memory.md`. Memory dies; files don't.
- **One model to rule them all.** Different models excel at different
  things — planner / coder / reviewer is a healthy split.
- **No rollback rehearsal.** If you can't `git revert` the last AI session
  cleanly, the commits were too big.

---

## 13. A Realistic Day-One Checklist

When starting a brand-new project:

- [ ] `git init` and push an empty repo.
- [ ] Copy this `README.md`, plus blank `AGENTS.md`, `.ai/memory.md`,
      `.ai/style.md`, `.ai/glossary.md`.
- [ ] Write **PRD-0001** for the smallest possible vertical slice.
- [ ] Write **ADR-0001** picking your stack.
- [ ] Scaffold with a deterministic tool (`create-vite`, `cargo new`, etc.) —
      *not* an LLM. LLMs are bad at scaffolding, great at filling.
- [ ] Add CI with the gates from §10 *before* writing feature code.
- [ ] Commit `prompts/system/default.md` referencing `AGENTS.md` and
      `.ai/style.md`.
- [ ] Open the editor's agent panel. Run `/plan` against PRD-0001. Iterate.
- [ ] Ship the slice end-to-end before adding feature #2. Resist the urge.

---

## 14. Further Reading & References

- **AGENTS.md spec** — <https://agents.md> (Agentic AI Foundation, Linux
  Foundation)
- **Architecture Decision Records** — Michael Nygard's original post; the
  `adr-tools` repo on GitHub
- **Spec-Driven Development with LLMs** — see `dev.to/openai` and
  Schemathesis docs
- **Anthropic — "Building effective agents"** (the canonical patterns post)
- **OpenAI — "A practical guide to building agents"** (the PDF playbook)
- **Simon Willison's blog** — best running commentary on day-to-day LLM
  coding workflows
- **Promptfoo** for prompt evaluation
- **Mermaid** + **Excalidraw** for diagrams that survive in git

---

## 15. The Smallest Possible Version

If you remember nothing else:

1. `README.md` for humans, `AGENTS.md` for agents — both at the root.
2. Every non-trivial decision becomes an ADR.
3. Every "TIL" becomes a line in `.ai/memory.md`.
4. Specs and tests are the contract; code is disposable.
5. Plan → critique → implement → review → commit, in small loops.
6. Promote prompts you reuse 3+ times into `skills/`.
7. Personal style lives in `.ai/style.md` and is referenced everywhere.

Build like that and any LLM — including a future one you've never heard of —
can pick up where you left off.

---

*This document is itself a living artifact. When something here stops being
true for you, change it. The repo is the memory.*

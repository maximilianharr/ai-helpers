# AI-Native App Template

> An opinionated template for building and maintaining production web applications
> where **AI agents are first-class contributors** — not just autocomplete assistants.

---

## The Core Idea

Traditional apps: humans write code, AI assists.
AI-native apps: AI writes code, humans approve and steer.

This template codifies that shift with concrete patterns for:
- **Spec-first development** — AI can only implement what is formally specified
- **Multi-agent pipelines** — specialized agents for spec writing, coding, QA, review, ops
- **Adversarial quality gates** — 3 competing LLMs review every change before merge
- **Continuous AI maintenance** — ops-agent monitors production and diagnoses incidents
- **Full traceability** — every line of code traces to a spec, a test, and a deployment

---

## Stack

| Layer | Technology |
|-------|-----------|
| Backend | Python 3.12, FastAPI, SQLAlchemy async, PostgreSQL |
| Frontend | Vanilla JS SPA (PWA), nginx |
| Containers | Podman (rootless), Podman Compose |
| Monitoring | Prometheus, Grafana, Alertmanager |
| CI/CD | GitHub Actions |
| AI Agents | GitHub Copilot coding agent + MCP servers |
| Agent Models | Claude Sonnet/Opus, GPT-5.x, Gemini |

---

## Repository Structure

```
ai-native-app-template/
│
├── .github/
│   ├── copilot-instructions.md   ← 🧠 AI agent context (READ THIS FIRST)
│   ├── AGENTS.md                 ← Agent roster: roles, triggers, escalation
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       ├── ci.yml                ← Lint → Test → Container build → AI review
│       └── deploy.yml            ← Staging → AI smoke test → Production (canary)
│
├── ai/
│   ├── agents/                   ← Agent YAML definitions
│   │   ├── dev-agent.yml         ← Implements features from specs
│   │   ├── qa-agent.yml          ← Generates edge-case tests
│   │   └── ops-agent.yml         ← Monitors production, diagnoses incidents
│   ├── prompts/                  ← Versioned prompt library
│   │   ├── codegen/              ← Feature implementation, spec writing
│   │   ├── review/               ← Adversarial code review
│   │   ├── test-gen/             ← Edge-case test generation
│   │   └── ops/                  ← Incident response, changelog
│   ├── mcp/
│   │   └── servers.json          ← MCP server config (github, filesystem, postgres, ...)
│   └── evals/
│       └── check-spec-compliance.py  ← LLM-as-judge: did the code implement the spec?
│
├── specs/                        ← SOURCE OF TRUTH — all work starts here
│   ├── README.md                 ← Spec lifecycle, traceability matrix rules
│   ├── features/
│   │   └── _template.md          ← Feature spec template (BDD acceptance criteria)
│   ├── adr/
│   │   └── 000-adr-template.md   ← Architecture Decision Record template
│   └── changelog/                ← AI-generated release notes
│
├── backend/
│   ├── app/
│   │   ├── main.py               ← FastAPI app: health, metrics, structured logging
│   │   ├── api/                  ← Route definitions (one file per feature)
│   │   ├── models/               ← Pydantic + SQLAlchemy models
│   │   ├── services/             ← Business logic (80% test coverage required)
│   │   └── repositories/         ← DB access layer
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── conftest.py           ← Shared fixtures: test DB, async client
│   ├── Containerfile             ← Multi-stage, non-root
│   └── pyproject.toml            ← deps, ruff, pytest, coverage config
│
├── frontend/
│   ├── src/                      ← SPA source
│   ├── tests/                    ← Vitest
│   ├── Containerfile             ← node builder → nginx runtime, non-root
│   └── nginx.conf                ← JSON logs, /api proxy, SPA fallback, security headers
│
├── infrastructure/
│   ├── podman/
│   │   ├── compose.yml           ← All services: backend, frontend, postgres, redis, monitoring
│   │   └── .env.template         ← All required env vars (copy to .env, never commit)
│   └── monitoring/
│       ├── prometheus.yml
│       └── alerts.yml            ← Alert rules that trigger ops-agent
│
├── tests/
│   ├── e2e/                      ← Playwright E2E (runs on staging)
│   └── ai-generated/             ← qa-agent output — DO NOT DELETE without human approval
│
├── docs/
│   ├── architecture.md           ← System diagram, tech choices, data flow
│   └── runbooks/                 ← ops-agent reads and updates these
│
└── scripts/
    ├── run-agent.sh              ← Manually invoke any agent
    ├── qa-check.sh               ← Local quality gate (run before opening PR)
    └── validate-specs.sh         ← Enforce spec ↔ code ↔ test traceability
```

---

## The RALF Loop — How Work Flows

```
 ┌──────────────────────────────────────────────────────────────────┐
 │  R — Requirements                                                │
 │  GitHub issue → spec-agent → specs/features/<slug>.md           │
 │  Human approves. Every AC is a test case.                       │
 └──────────────────────┬───────────────────────────────────────────┘
                        │ label: spec-approved
 ┌──────────────────────▼───────────────────────────────────────────┐
 │  A — Architecture                                                │
 │  Structural changes → ADR in specs/adr/                         │
 │  AI proposes, humans approve. Agents check ADRs before coding.  │
 └──────────────────────┬───────────────────────────────────────────┘
                        │
 ┌──────────────────────▼───────────────────────────────────────────┐
 │  L — Lifecycle (Implement → Review → Deploy)                     │
 │  dev-agent codes → qa-agent tests → review-agent (3 models)     │
 │  → human approve → canary deploy → full production              │
 └──────────────────────┬───────────────────────────────────────────┘
                        │
 ┌──────────────────────▼───────────────────────────────────────────┐
 │  F — Feedback                                                    │
 │  ops-agent monitors → alerts → diagnosis → fix issue            │
 │  Post-mortems feed back into specs + runbooks                   │
 └──────────────────────┬───────────────────────────────────────────┘
                        │ loop
                        └──────────────────────────────────────────►
```

---

## Quality Gates (nothing merges without these)

| Gate | Tool | Blocks merge? |
|------|------|--------------|
| Secret scan | gitleaks | ✅ Yes |
| Python lint | ruff | ✅ Yes |
| Backend tests | pytest | ✅ Yes |
| Test coverage ≥ 80% | pytest-cov | ✅ Yes |
| Frontend tests | vitest | ✅ Yes |
| Container build | podman build | ✅ Yes |
| Spec traceability | validate-specs.sh | ✅ Yes |
| AI adversarial review (3 models) | review-agent | CRITICAL findings block |
| E2E tests | Playwright (staging) | ✅ Yes |
| Human PR approval | GitHub | ✅ Yes |
| Production canary (5 min) | scripts/check-canary-metrics.sh | ✅ Yes |

---

## MCP Servers Used

| Server | Purpose | Agents |
|--------|---------|--------|
| `github` | Issues, PRs, code search | all |
| `filesystem` | Read/write workspace | dev, qa, ops |
| `postgres` | Read-only DB queries | ops |
| `prometheus` | Metrics queries | ops |
| `sequential-thinking` | Multi-step reasoning | spec, ops |
| `memory` | Cross-session knowledge | dev, ops |

---

## Key Design Decisions

### Why spec-first?
Without specs, AI agents have no ground truth. They implement plausible-sounding features
that may not match intent. Specs give agents a contract and give humans an approval gate
before work starts — not after.

### Why adversarial review with 3 models?
Each model has different blind spots. GPT misses security issues that Claude finds. Gemini
catches API surface problems others miss. Running all three in parallel with role-specific
prompts dramatically reduces the review blind spots compared to any single model.

### Why Podman instead of Docker?
Rootless by default. No daemon. Better for production security — containers run as your
user, not root. Fully compatible with Docker Compose syntax (`podman compose`).

### Why not Kubernetes?
Single-host Podman Compose is sufficient for most companies' initial production load and
dramatically simpler to operate and for AI agents to reason about. When you need K8s,
the Containerfiles and compose.yml map directly to Helm charts.

### Why versioned prompts in `ai/prompts/`?
Prompts are code. If you change a prompt and the agent starts generating different output,
you need to know why and be able to roll back. Versioned prompts in git give you full history.

### Why `tests/ai-generated/` as first-class?
AI-generated tests often catch edge cases humans miss. Deleting them because they're
"AI-generated" loses that value. Treat them as production tests — review, don't blindly delete.

---

## Getting Started

```bash
# 1. Clone / use as template
git clone https://github.com/your-org/ai-native-app-template myapp
cd myapp

# 2. Copy env template
cp infrastructure/podman/.env.template infrastructure/podman/.env
# Edit .env with your values

# 3. Start everything
cd infrastructure/podman
podman compose up -d

# 4. Verify
curl http://localhost:8080/health          # frontend
curl http://localhost:8080/api/health      # backend (proxied)

# 5. Start your first feature
# Create a GitHub issue, then:
scripts/run-agent.sh spec-agent <issue-number>
```

---

## Adapting This Template

1. **Add features**: Create an issue → `spec-agent` → `dev-agent`
2. **Add an agent**: Copy an existing `ai/agents/*.yml`, add prompt in `ai/prompts/`,
   add GitHub Actions trigger in `.github/workflows/agents.yml`
3. **Change the stack**: Write an ADR first, then let `dev-agent` implement the migration
4. **Scale up**: Replace Podman Compose with Kubernetes — Containerfiles don't change,
   write a Helm chart from compose.yml

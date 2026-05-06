# Copilot / AI Agent Instructions

> This file is the **single source of truth** for every AI agent working on this repository.
> It is read automatically by GitHub Copilot, Cursor, and any agent that follows the AGENTS.md spec.
> Keep it up-to-date. An outdated instruction file is a bug.

---

## 🎯 Project Purpose

A production-grade, AI-native web application with a FastAPI backend and JavaScript/nginx
frontend, packaged entirely in Podman containers. The system is designed to be built,
reviewed, tested, and maintained primarily by AI agents with human approval gates.

---

## 🏗️ Architecture at a Glance

```
┌─────────────────────────────────────────────────────────┐
│  Client (browser / mobile PWA)                          │
└───────────────────┬─────────────────────────────────────┘
                    │ HTTPS
┌───────────────────▼─────────────────────────────────────┐
│  frontend container  (nginx + static JS/HTML)           │
│  • serves SPA                                           │
│  • reverse-proxies /api/* → backend                     │
└───────────────────┬─────────────────────────────────────┘
                    │ HTTP (internal network)
┌───────────────────▼─────────────────────────────────────┐
│  backend container  (Python 3.12 + FastAPI + uvicorn)   │
│  • REST + optional WebSocket endpoints                  │
│  • business logic, auth, data access                    │
└───────────────────┬─────────────────────────────────────┘
                    │
       ┌────────────┴────────────┐
       ▼                        ▼
  postgres container       redis container
  (persistent data)        (cache / sessions)
```

All containers are defined in `infrastructure/podman/compose.yml`.

---

## 📂 Repository Layout (mandatory understanding)

| Path | Purpose |
|------|---------|
| `specs/features/` | **Spec-first**: every feature starts here. Never write code without a spec. |
| `specs/adr/` | Architecture Decision Records. Read before proposing structural changes. |
| `ai/agents/` | YAML definitions for each agent role (dev, qa, ops, spec). |
| `ai/prompts/` | Versioned prompt library. Reuse before writing new prompts. |
| `ai/mcp/` | MCP server configuration. |
| `ai/evals/` | Evaluation harnesses for LLM output quality. |
| `backend/` | FastAPI application. |
| `frontend/` | JS SPA + nginx config. |
| `infrastructure/` | Podman compose, monitoring, secrets templates. |
| `tests/e2e/` | End-to-end tests (Playwright). |
| `tests/ai-generated/` | AI-generated edge-case tests — treat as first-class, don't delete. |

---

## ✅ Coding Standards

### General
- **Spec-first**: Before implementing any feature, a spec MUST exist in `specs/features/`.
  The spec filename is the feature slug (e.g., `user-auth.md`).
- **No magic values**: All config comes from env vars. See `.env.template`.
- **No secrets in code**: Use `os.getenv()` / `process.env`. Secrets live in Podman secrets or Vault.
- **Observability by default**: Every service endpoint must emit structured JSON logs and
  expose `/health` and `/metrics` endpoints.

### Backend (Python / FastAPI)
- Python 3.12+, type hints everywhere, Pydantic v2 models.
- Use `app/api/` for route definitions, `app/services/` for business logic,
  `app/models/` for Pydantic + SQLAlchemy models.
- All database access through the repository pattern (`app/repositories/`).
- Async-first: prefer `async def` for I/O-bound operations.
- Error handling: use FastAPI `HTTPException` with meaningful status codes.
  Never swallow exceptions silently.
- Tests live in `backend/tests/`. Use `pytest` + `pytest-asyncio`.
  Minimum 80% coverage on `app/services/`.

### Frontend (JavaScript / nginx)
- Vanilla JS or lightweight framework (check `specs/adr/` for current decision).
- Mobile-first responsive design. Test at 375px, 768px, 1440px breakpoints.
- API calls only through `src/api/client.js` — never fetch directly in components.
- Tests in `frontend/tests/` using Vitest.

### Containers
- Use `Containerfile` (not `Dockerfile`) — we're Podman-native.
- Multi-stage builds only. Final stage must be non-root user.
- Pin base image digests in production builds.

---

## 🔄 Development Loop (RALF — Requirements → Architecture → Lifecycle → Feedback)

1. **Requirements**: New work starts in `specs/features/<slug>.md` using the feature template.
   GitHub issue links to the spec file.
2. **Architecture**: If structural, add an ADR in `specs/adr/`. AI agents propose; humans approve.
3. **Lifecycle**: Implement → AI-review (adversarial) → tests pass → deploy to staging.
4. **Feedback**: Staging metrics + user feedback → update spec → next increment.

---

## 🤖 Agent Roles (see `ai/agents/` for full definitions)

| Agent | Trigger | Responsibility |
|-------|---------|---------------|
| `spec-agent` | Issue labeled `needs-spec` | Converts user story → formal spec |
| `dev-agent` | Spec approved (label `spec-approved`) | Implements feature, writes tests |
| `qa-agent` | PR opened | Generates additional edge-case tests, runs evals |
| `review-agent` | PR opened | Adversarial code review (3 models for 🔴 files) |
| `ops-agent` | Alert fired / deployment | Diagnoses incidents, proposes runbook updates |
| `changelog-agent` | Release tag | Generates human-readable changelog from commits |

---

## 🚫 Hard Rules for All Agents

1. Never commit directly to `main`. Always use a branch + PR.
2. Never merge a PR with failing tests or open `review-agent` findings rated CRITICAL.
3. Never hardcode URLs, credentials, or environment names.
4. Never delete `tests/ai-generated/` tests without human approval.
5. Always update the spec file when behavior changes — code and spec must stay in sync.
6. All agent actions must be traceable: log the prompt, model, and output hash.

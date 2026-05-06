# Architecture — AI-Native App

> This document is the architectural overview. It is maintained by both humans and AI agents.
> The `ops-agent` updates the "Known Issues" section after incidents.
> ADRs in `specs/adr/` contain the reasoning behind each design choice.

---

## System Overview

```
                     ┌─────────────────────────────────────────┐
                     │           Client Layer                   │
                     │  Browser (desktop/mobile)                │
                     │  Progressive Web App (PWA)               │
                     └──────────────┬──────────────────────────┘
                                    │ HTTPS
                     ┌──────────────▼──────────────────────────┐
                     │         Frontend Container               │
                     │  nginx 1.27 (non-root, port 8080)        │
                     │  Serves SPA, proxies /api/* → backend    │
                     └──────────────┬──────────────────────────┘
                                    │ HTTP (internal network: app-net)
                     ┌──────────────▼──────────────────────────┐
                     │         Backend Container                │
                     │  Python 3.12 + FastAPI + uvicorn         │
                     │  /health  /metrics  /api/*               │
                     └────────┬────────────────┬───────────────┘
                              │                │
               ┌──────────────▼───┐    ┌───────▼────────────┐
               │    PostgreSQL 16 │    │     Redis 7         │
               │  (persistent DB) │    │  (cache/sessions)   │
               └──────────────────┘    └────────────────────┘

                     ┌──────────────────────────────────────────┐
                     │         Monitoring (monitoring-net)       │
                     │  Prometheus 2.55  ←  scrapes /metrics     │
                     │  Grafana 11.3     ←  dashboards           │
                     │  Alertmanager     →  ops-agent webhook    │
                     └──────────────────────────────────────────┘
```

---

## AI Agent Layer

```
GitHub Issues / Labels
        │
        ▼
┌───────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  spec-agent   │───►│  dev-agent   │───►│  qa-agent    │    │  ops-agent   │
│               │    │              │    │              │    │              │
│ Issue →       │    │ Spec →       │    │ PR →         │    │ Alert →      │
│ Spec draft    │    │ Feature PR   │    │ Edge tests   │    │ Diagnosis    │
└───────────────┘    └──────────────┘    └──────┬───────┘    └──────────────┘
                                                │                    ▲
                                         ┌──────▼───────┐           │
                                         │ review-agent │           │
                                         │              │     Prometheus
                                         │ 3-model      │     Alertmanager
                                         │ adversarial  │
                                         │ review       │
                                         └──────────────┘

All agents communicate through GitHub (issues/PRs/labels) — auditable by design.
```

---

## Technology Choices

| Layer | Technology | ADR |
|-------|-----------|-----|
| Backend language | Python 3.12 | — |
| Backend framework | FastAPI | specs/adr/001-fastapi.md |
| ORM | SQLAlchemy 2 async | specs/adr/002-sqlalchemy.md |
| Database | PostgreSQL 16 | specs/adr/003-postgres.md |
| Cache/sessions | Redis 7 | — |
| Frontend | Vanilla JS / lightweight SPA | specs/adr/004-frontend.md |
| Web server | nginx 1.27 | — |
| Containers | Podman (rootless) | specs/adr/005-podman.md |
| Container orchestration | Podman Compose (single host) | — |
| Metrics | Prometheus + Grafana | — |
| Logging | structlog (JSON) | — |
| Auth | JWT (python-jose) | specs/adr/006-auth.md |
| CI/CD | GitHub Actions | — |
| AI agents | GitHub Copilot coding agent | — |
| Agent context | MCP servers | — |

---

## Security Model

- **Non-root containers**: both backend (uid 1001) and frontend (nginx user) run unprivileged.
- **Network isolation**: `app-net` (app services) and `monitoring-net` (metrics) are separate.
  The database is never exposed to the host network.
- **Secrets**: injected via env vars from Podman secrets or CI vault. Never in code or images.
- **TLS**: terminated upstream (CDN / reverse proxy). Internal traffic is HTTP.
- **Auth**: JWT with short expiry (1h) + refresh tokens. Stored in httpOnly cookies.
- **AI agent access**: agents use fine-grained GitHub PATs and read-only DB connections.
  No agent has write access to production data.

---

## Data Flow: Feature Request → Production

```
1. User/PM creates GitHub issue
         │
2. spec-agent converts to specs/features/<slug>.md
         │ PR: spec-draft
3. Human approves spec
         │ label: spec-approved
4. dev-agent implements feature + tests
         │ PR: feature/<slug>
5. qa-agent generates edge-case tests
         │ label: tests-ok
6. review-agent (3 models) reviews diff
         │ no CRITICAL findings
7. Human approves PR → merge to staging
         │
8. CI builds containers, deploys to staging
         │
9. AI smoke tests run on staging
         │
10. Human approves production deploy (GitHub Environment gate)
         │
11. Canary deploy (10% traffic) → monitor 5 min → full traffic
         │
12. changelog-agent generates release notes
```

---

## Mobile Support

The frontend is a **Progressive Web App (PWA)**:
- Responsive design (mobile-first, tested at 375px / 768px / 1440px)
- Service Worker for offline caching of static assets
- Web App Manifest for "Add to Home Screen"
- Same codebase — no separate mobile app

---

## Known Issues & Limitations

<!-- ops-agent appends to this section after post-mortems -->

| Issue | Severity | Status | Date |
|-------|----------|--------|------|
| Single-host Podman Compose — no HA | Medium | By design (see ADR-005) | — |

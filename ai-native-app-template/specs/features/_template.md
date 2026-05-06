# Feature Spec Template
# Copy this file to specs/features/<feature-slug>.md and fill it in.
# The spec-agent uses this template. Humans and agents must both approve before implementation.

---

# Feature: <title>

**Slug**: `<feature-slug>`  
**Issue**: #<issue-number>  
**Status**: `draft` | `review` | `approved` | `implemented` | `deprecated`  
**Author**: <@github-username or agent:spec-agent>  
**Created**: YYYY-MM-DD  
**Last updated**: YYYY-MM-DD  

---

## 1. Problem Statement

<!-- Why does this feature exist? What user pain does it solve?
     One paragraph. No solution yet. -->

---

## 2. User Stories

<!-- Standard format: "As a <role>, I want <action> so that <benefit>." -->

- As a **[role]**, I want **[action]** so that **[benefit]**.

---

## 3. Acceptance Criteria

<!-- These become the test cases. Be concrete. No vague language.
     Use "GIVEN / WHEN / THEN" (BDD) format.
     The qa-agent will generate tests from this section directly. -->

### AC-1: <short name>
**GIVEN** <precondition>  
**WHEN** <action>  
**THEN** <expected result>  
**AND** <additional assertion>  

### AC-2: <short name>
...

### AC-N: Error case
**GIVEN** <invalid state>  
**WHEN** <action>  
**THEN** the system returns HTTP 4xx with error body `{"error": "<message>"}`  

---

## 4. Out of Scope

<!-- Explicit exclusions prevent scope creep. -->

- ❌ <thing we are NOT doing>

---

## 5. API Contract (if backend change)

### Endpoint: `<METHOD> /api/<path>`

**Request**:
```json
{
  "field": "type — description"
}
```

**Response** (`200 OK`):
```json
{
  "field": "type — description"
}
```

**Error responses**:
| Status | Condition |
|--------|-----------|
| `400` | Invalid input |
| `401` | Not authenticated |
| `404` | Resource not found |

---

## 6. Data Model (if DB change)

```sql
-- New table or migration description
-- dev-agent generates the actual Alembic migration
```

---

## 7. UI/UX Notes (if frontend change)

- Mobile breakpoint behaviour: ...
- Loading/error/empty states: ...
- Link to mockup (Figma, etc.): ...

---

## 8. Non-Functional Requirements

| Concern | Requirement |
|---------|------------|
| Performance | p99 response time < 500ms under 100 RPS |
| Security | Endpoint requires JWT auth (scope: `<scope>`) |
| Observability | Log at INFO on success, ERROR on failure with request ID |
| Backwards compat | Non-breaking — existing clients unaffected |

---

## 9. Implementation Notes

<!-- Optional hints for the dev-agent. Not requirements. -->

- Suggested file(s): `backend/app/services/<slug>.py`
- Reuse: check `backend/app/services/` for similar patterns first

---

## 10. Test Strategy

<!-- The qa-agent generates tests from AC above, but list any special concerns. -->

- Load test at 200 RPS for 2 minutes (staging only)
- Security: OWASP input fuzzing on all string fields

---

## Approval

| Role | Decision | Date | Notes |
|------|----------|------|-------|
| Product | ☐ Approved / ☐ Changes needed | | |
| Engineering | ☐ Approved / ☐ Changes needed | | |
| Security (if 🔴) | ☐ Approved / ☐ N/A | | |

#!/usr/bin/env bash
# qa-check.sh
# ===========
# Local quality gate — run this before opening a PR.
# The dev-agent runs this automatically; humans can run it manually.
# Exits 0 only if ALL checks pass.

set -euo pipefail

PASS=0
FAIL=0

run_check() {
    local name="$1"
    local cmd="$2"
    printf "  %-40s" "$name"
    if eval "$cmd" &>/dev/null; then
        echo "✅"
        PASS=$((PASS + 1))
    else
        echo "❌"
        FAIL=$((FAIL + 1))
        eval "$cmd" 2>&1 | head -20 | sed 's/^/    /'
    fi
}

echo "═══════════════════════════════════════════════"
echo "  QA Check"
echo "═══════════════════════════════════════════════"
echo ""

echo "── Secrets ─────────────────────────────────────"
run_check "No secrets in staged files" "gitleaks detect --source=. --no-git -q"

echo ""
echo "── Backend ─────────────────────────────────────"
run_check "Ruff lint"           "cd backend && ruff check app/"
run_check "Ruff format check"   "cd backend && ruff format --check app/"
run_check "Unit tests"          "cd backend && pytest tests/unit/ -q"
run_check "Integration tests"   "cd backend && pytest tests/integration/ -q"
run_check "Coverage >= 80%"     "cd backend && pytest --cov=app --cov-fail-under=80 -q tests/"

echo ""
echo "── Frontend ────────────────────────────────────"
run_check "ESLint"              "cd frontend && npx eslint src/ --max-warnings=0"
run_check "Vitest"              "cd frontend && npm run test -- --run"

echo ""
echo "── Specs ───────────────────────────────────────"
run_check "Spec traceability"   "scripts/validate-specs.sh"

echo ""
echo "── Container Build ─────────────────────────────"
run_check "Backend builds"      "podman build -f backend/Containerfile backend/ -q"
run_check "Frontend builds"     "podman build -f frontend/Containerfile frontend/ -q"

echo ""
echo "═══════════════════════════════════════════════"
echo "  Results: ✅ $PASS passed   ❌ $FAIL failed"
echo "═══════════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "Fix failures before opening a PR."
    exit 1
fi
exit 0

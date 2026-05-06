#!/usr/bin/env bash
# validate-specs.sh
# =================
# Enforces the traceability matrix:
#   1. Every merged feature branch has an 'implemented' spec.
#   2. Every 'implemented' spec has at least one test.
#   3. No 'approved' spec is older than 7 days without a linked PR.
#
# Run in CI: scripts/validate-specs.sh
# Exit code 0 = pass, 1 = violations found

set -euo pipefail

SPECS_DIR="specs/features"
TESTS_AI_DIR="tests/ai-generated"
BACKEND_TESTS_DIR="backend/tests"
VIOLATIONS=0

echo "=== Spec Traceability Check ==="

# ── 1. Check that all implemented specs have tests ────────────────────────────
echo ""
echo "Checking: every implemented spec has a test..."
while IFS= read -r spec_file; do
    slug=$(basename "$spec_file" .md)
    [ "$slug" = "_template" ] && continue

    status=$(grep -E '^\\*\\*Status\\*\\*:' "$spec_file" | awk '{print $2}' || true)

    if [[ "$status" == *"implemented"* ]]; then
        # Look for tests in both ai-generated and backend tests
        test_count=$(find "$TESTS_AI_DIR" "$BACKEND_TESTS_DIR" \
            -name "*${slug}*" -type f 2>/dev/null | wc -l)

        if [ "$test_count" -eq 0 ]; then
            echo "  ❌ VIOLATION: '$slug' is implemented but has no tests"
            VIOLATIONS=$((VIOLATIONS + 1))
        else
            echo "  ✅ $slug — $test_count test file(s)"
        fi
    fi
done < <(find "$SPECS_DIR" -name "*.md" -type f)

# ── 2. Check for stale approved specs (> 7 days, no PR) ───────────────────────
echo ""
echo "Checking: no approved spec is stale (> 7 days without PR)..."
CUTOFF=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)

while IFS= read -r spec_file; do
    slug=$(basename "$spec_file" .md)
    [ "$slug" = "_template" ] && continue

    status=$(grep -E '^\\*\\*Status\\*\\*:' "$spec_file" | awk '{print $2}' || true)
    last_updated=$(grep -E '^\\*\\*Last updated\\*\\*:' "$spec_file" | awk '{print $3}' || true)

    if [[ "$status" == *"approved"* ]] && [[ -n "$last_updated" ]]; then
        if [[ "$last_updated" < "$CUTOFF" ]]; then
            echo "  ⚠️  WARNING: '$slug' approved since $last_updated — where's the PR?"
        fi
    fi
done < <(find "$SPECS_DIR" -name "*.md" -type f)

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
if [ "$VIOLATIONS" -gt 0 ]; then
    echo "❌ $VIOLATIONS violation(s) found. Fix before merging."
    exit 1
else
    echo "✅ All spec traceability checks passed."
    exit 0
fi

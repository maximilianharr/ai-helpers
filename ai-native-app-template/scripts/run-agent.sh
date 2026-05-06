#!/usr/bin/env bash
# run-agent.sh
# ============
# Manually invoke an AI agent from the command line.
# This wraps the GitHub Copilot coding agent CLI (or a local agent runner).
#
# Usage:
#   scripts/run-agent.sh <agent-name> [args...]
#
# Examples:
#   scripts/run-agent.sh spec-agent 42              # Convert issue #42 to spec
#   scripts/run-agent.sh dev-agent user-auth        # Implement feature slug
#   scripts/run-agent.sh ops-agent --incident 99    # Diagnose alert #99
#   scripts/run-agent.sh qa-agent                   # Run on current staged diff

set -euo pipefail

AGENT="$1"
shift || true
AGENT_CONFIG="ai/agents/${AGENT}.yml"

if [ ! -f "$AGENT_CONFIG" ]; then
    echo "❌ Unknown agent: $AGENT"
    echo "   Available agents: $(ls ai/agents/*.yml | xargs -I{} basename {} .yml)"
    exit 1
fi

echo "🤖 Launching $AGENT..."
echo "   Config: $AGENT_CONFIG"
echo "   Args: $*"
echo ""

# ── Option A: GitHub Copilot CLI (if available) ───────────────────────────────
if command -v gh &>/dev/null && gh extension list 2>/dev/null | grep -q copilot; then
    gh copilot agent run \
        --config "$AGENT_CONFIG" \
        --mcp-config ai/mcp/servers.json \
        "$@"

# ── Option B: Direct API call via Python runner ────────────────────────────────
elif command -v python3 &>/dev/null; then
    python3 scripts/_agent_runner.py \
        --config "$AGENT_CONFIG" \
        --mcp-config ai/mcp/servers.json \
        "$@"

else
    echo "❌ No agent runtime found."
    echo "   Install GitHub CLI + Copilot extension, or Python 3."
    exit 1
fi

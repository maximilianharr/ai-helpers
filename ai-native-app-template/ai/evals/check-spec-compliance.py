"""
Spec Compliance Eval
====================
Checks that a code diff actually implements what the spec says.
This is an LLM-as-judge evaluation used by the qa-agent.

Usage:
    python check-spec-compliance.py --spec specs/features/user-auth.md --diff /tmp/pr.diff

Exit codes:
    0 = all ACs appear to be implemented
    1 = one or more ACs are missing from the diff
    2 = error running the eval
"""

import argparse
import json
import os
import sys
from pathlib import Path

# pip install openai anthropic
try:
    import anthropic
except ImportError:
    print("Install anthropic: pip install anthropic", file=sys.stderr)
    sys.exit(2)


JUDGE_PROMPT = """
You are evaluating whether a code diff implements a feature spec.

## Spec
{spec}

## Diff
{diff}

## Task
For each acceptance criterion (AC) in the spec, determine:
- Is it IMPLEMENTED (the diff contains code that addresses this AC)?
- Is it MISSING (no corresponding code in the diff)?
- Is it UNTESTABLE (can't determine from diff alone)?

Respond in JSON:
{{
  "verdict": "PASS" | "FAIL" | "PARTIAL",
  "coverage_pct": <0-100>,
  "results": [
    {{
      "ac_id": "AC-1",
      "title": "short AC title",
      "status": "IMPLEMENTED" | "MISSING" | "UNTESTABLE",
      "evidence": "quote from diff or explain why missing"
    }}
  ],
  "summary": "one sentence"
}}
"""


def run_eval(spec_path: str, diff_path: str) -> dict:
    spec = Path(spec_path).read_text()
    diff = Path(diff_path).read_text()

    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    response = client.messages.create(
        model="claude-sonnet-4-5",
        max_tokens=2000,
        messages=[
            {
                "role": "user",
                "content": JUDGE_PROMPT.format(spec=spec, diff=diff),
            }
        ],
    )

    text = response.content[0].text
    # Extract JSON from the response
    start = text.find("{")
    end = text.rfind("}") + 1
    return json.loads(text[start:end])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--diff", required=True)
    parser.add_argument("--output", default=None, help="Write JSON report to file")
    args = parser.parse_args()

    try:
        result = run_eval(args.spec, args.diff)
    except Exception as e:
        print(f"Eval error: {e}", file=sys.stderr)
        sys.exit(2)

    report = json.dumps(result, indent=2)
    print(report)

    if args.output:
        Path(args.output).write_text(report)

    missing = [r for r in result["results"] if r["status"] == "MISSING"]
    if missing:
        print(f"\n⚠️  Missing ACs: {[r['ac_id'] for r in missing]}", file=sys.stderr)
        sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main()

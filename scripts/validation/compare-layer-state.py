#!/usr/bin/env python3
"""Fail on unexplained baseline/candidate build-state differences."""

from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from pathlib import Path


def files(root: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for path in sorted(root.rglob("*")):
        if path.is_file() and path.name != "metadata.json":
            result[str(path.relative_to(root))] = path.read_text(errors="replace").splitlines()
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--tuple", required=True)
    parser.add_argument("--contract", required=True, type=Path)
    args = parser.parse_args()

    contract = json.loads(args.contract.read_text())
    rules = contract.get("allowed_deltas", {}).get(args.tuple, [])
    compiled: list[tuple[re.Pattern[str], re.Pattern[str], str]] = []
    for rule in rules:
        try:
            compiled.append((
                re.compile(rule["file"]),
                re.compile(rule["pattern"]),
                str(rule["reason"]).strip(),
            ))
        except (KeyError, re.error) as exc:
            print(f"ERROR: invalid allow rule for {args.tuple}: {exc}", file=sys.stderr)
            return 2
    if any(not reason for _, _, reason in compiled):
        print("ERROR: every allowed delta needs a reason", file=sys.stderr)
        return 2

    old, new = files(args.baseline), files(args.candidate)
    unexplained: list[str] = []
    for name in sorted(set(old) | set(new)):
        if old.get(name) == new.get(name):
            continue
        delta = list(difflib.unified_diff(old.get(name, []), new.get(name, []), lineterm=""))
        changed_lines = [
            line[1:] for line in delta
            if line.startswith(("+", "-")) and not line.startswith(("+++", "---"))
        ]
        for line in changed_lines:
            if not any(file_re.search(name) and line_re.search(line) for file_re, line_re, _ in compiled):
                unexplained.append(f"{name}: {line}")

    if unexplained:
        print(f"ERROR: unexplained build deltas for {args.tuple}:", file=sys.stderr)
        for line in unexplained[:250]:
            print(f"  {line}", file=sys.stderr)
        if len(unexplained) > 250:
            print(f"  ... {len(unexplained) - 250} more", file=sys.stderr)
        return 1
    print(f"PASS: {args.tuple} has no unexplained layer-adoption delta")
    return 0


if __name__ == "__main__":
    sys.exit(main())

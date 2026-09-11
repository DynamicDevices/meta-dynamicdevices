#!/usr/bin/env python3
"""Detect layer topology/pin changes and enforce an explicit adoption contract."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


MATERIAL_PATHS = (
    re.compile(r"^\.gitmodules$"),
    re.compile(r"(^|/)conf/layer\.conf$"),
    re.compile(r"^kas/.*\.ya?ml$"),
)
def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--contract", default="ci/layer-adoption-contract.json")
    parser.add_argument("--github-output")
    args = parser.parse_args()

    changed = git("diff", "--name-only", f"{args.base}...{args.head}").splitlines()
    material_files = [
        path for path in changed
        if any(pattern.search(path) for pattern in MATERIAL_PATHS)
    ]
    # Treat every KAS change as material. YAML context makes line-only pin
    # detection easy to evade (for example by adding a list item below an
    # existing `includes:` key), and a false-positive build is safer than a
    # layer adoption escaping the hard gate.
    material = bool(material_files)

    if material:
        if args.contract not in changed:
            print(
                f"ERROR: material Yocto layer change requires {args.contract} "
                "to be updated in the same change",
                file=sys.stderr,
            )
            return 2
        try:
            contract = json.loads(Path(args.contract).read_text())
        except (OSError, json.JSONDecodeError) as exc:
            print(f"ERROR: invalid adoption contract: {exc}", file=sys.stderr)
            return 2
        if contract.get("schema") != 1 or not str(contract.get("reason", "")).strip():
            print("ERROR: contract needs schema=1 and a non-empty reason", file=sys.stderr)
            return 2
        if not isinstance(contract.get("allowed_deltas"), dict):
            print("ERROR: allowed_deltas must be an object", file=sys.stderr)
            return 2

    result = "true" if material else "false"
    print(f"material={result}")
    if material_files:
        print("material candidates:")
        for path in material_files:
            print(f"  {path}")
    if args.github_output:
        with open(args.github_output, "a", encoding="utf-8") as output:
            output.write(f"material={result}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())

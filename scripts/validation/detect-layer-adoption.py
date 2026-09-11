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
    re.compile(r"^ci/layer-adoption-tuples\.json$"),
)

REQUIRED_TUPLE_FIELDS = ("id", "machine", "distro", "image", "config")


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True)


def parse_tuples(raw: str, source: str) -> dict[str, dict[str, str]]:
    try:
        document = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"{source}: invalid JSON: {exc}") from exc
    if document.get("schema") != 1 or not isinstance(document.get("tuples"), list):
        raise ValueError(f"{source}: expected schema=1 and a tuples array")

    result: dict[str, dict[str, str]] = {}
    for index, entry in enumerate(document["tuples"]):
        if not isinstance(entry, dict):
            raise ValueError(f"{source}: tuple {index} is not an object")
        missing = [field for field in REQUIRED_TUPLE_FIELDS if not str(entry.get(field, "")).strip()]
        if missing:
            raise ValueError(f"{source}: tuple {index} lacks {', '.join(missing)}")
        tuple_id = str(entry["id"])
        if tuple_id in result:
            raise ValueError(f"{source}: duplicate tuple id {tuple_id}")
        result[tuple_id] = {field: str(entry[field]) for field in REQUIRED_TUPLE_FIELDS}
    if not result:
        raise ValueError(f"{source}: tuple matrix must not be empty")
    return result


def validate_tuple_matrix(base: str, path: Path) -> None:
    candidate = parse_tuples(path.read_text(encoding="utf-8"), str(path))
    missing_configs = sorted(
        tuple_id for tuple_id, entry in candidate.items()
        if not Path(entry["config"]).is_file()
    )
    if missing_configs:
        raise ValueError(
            f"{path}: tuple configs do not exist for: {', '.join(missing_configs)}"
        )

    baseline_result = subprocess.run(
        ["git", "show", f"{base}:{path.as_posix()}"],
        check=False,
        capture_output=True,
        text=True,
    )
    if baseline_result.returncode != 0:
        # Bootstrap case: the gate and its matrix are being introduced together.
        return
    baseline_raw = baseline_result.stdout
    baseline = parse_tuples(baseline_raw, f"{base}:{path}")
    removed = sorted(set(baseline) - set(candidate))
    changed = sorted(
        tuple_id for tuple_id in set(baseline) & set(candidate)
        if baseline[tuple_id] != candidate[tuple_id]
    )
    if removed or changed:
        details = []
        if removed:
            details.append("removed=" + ",".join(removed))
        if changed:
            details.append("redefined=" + ",".join(changed))
        raise ValueError(
            "protected baseline tuples may only be extended, not removed or redefined ("
            + "; ".join(details) + ")"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--contract", default="ci/layer-adoption-contract.json")
    parser.add_argument("--tuples", default="ci/layer-adoption-tuples.json")
    parser.add_argument("--github-output")
    args = parser.parse_args()

    try:
        validate_tuple_matrix(args.base, Path(args.tuples))
    except (OSError, ValueError) as exc:
        print(f"ERROR: invalid protected tuple matrix: {exc}", file=sys.stderr)
        return 2

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

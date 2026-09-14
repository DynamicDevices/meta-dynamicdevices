#!/usr/bin/env python3
"""Canonicalise bitbake-layers reports without discarding policy evidence."""

from __future__ import annotations

import argparse
import re
import sys


VOLATILE_PREFIXES = ("Loaded ", "Parsing of ")


def canonicalise_feature_sets(line: str) -> str:
    def replace(match: re.Match[str]) -> str:
        words = match.group(1).split()
        if len(words) > 1 and all(re.fullmatch(r"[A-Za-z0-9+_.-]+", word) for word in words):
            return "'" + " ".join(sorted(words)) + "'"
        return match.group(0)

    return re.sub(r"'([^']+)'", replace, line)


def canonicalise_blocks(lines: list[str]) -> list[str]:
    result: list[str] = []
    heading = ""
    for raw in lines:
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith(VOLATILE_PREFIXES):
            continue
        if not line[:1].isspace() and stripped.endswith(":"):
            heading = stripped[:-1]
            result.append(f"entry\t{heading}")
        elif line[:1].isspace() and heading:
            result.append(f"value\t{heading}\t{canonicalise_feature_sets(stripped)}")
        else:
            heading = ""
            result.append(f"message\t{canonicalise_feature_sets(stripped)}")
    return sorted(result)


def canonicalise_layers(lines: list[str]) -> list[str]:
    result: list[str] = []
    for raw in lines:
        fields = raw.split()
        if not fields or fields[:3] == ["layer", "path", "priority"]:
            continue
        if len(fields) == 3 and fields[2].lstrip("-").isdigit():
            result.append("\t".join(("layer", *fields)))
        else:
            result.append("message\t" + canonicalise_feature_sets(raw.strip()))
    return sorted(result)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("layers", "appends", "recipes"))
    args = parser.parse_args()
    lines = sys.stdin.read().splitlines()
    output = canonicalise_layers(lines) if args.mode == "layers" else canonicalise_blocks(lines)
    if output:
        print("\n".join(output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

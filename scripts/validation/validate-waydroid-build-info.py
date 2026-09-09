#!/usr/bin/env python3
"""Validate Android build provenance before a Waydroid host build."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("build_info", type=Path)
    parser.add_argument(
        "--release-mode", choices=("integration", "production"), required=True
    )
    args = parser.parse_args()

    info = json.loads(args.build_info.read_text(encoding="utf-8"))
    targets = info.get("targets", [])
    imx8mm_targets = [
        target
        for target in targets
        if "lineage_waydroid_aesl_2gb_arm64_only-bp4a-" in target
    ]
    if len(imx8mm_targets) != 1:
        raise SystemExit("build-info must contain exactly one AESL i.MX8MM target")
    if not imx8mm_targets[0].endswith(("-user", "-userdebug")):
        raise SystemExit("build-info contains an unrecognised i.MX8MM variant")

    if args.release_mode == "production":
        required = {
            "imx8mm_variant": "user",
            "release_class": "production",
            "selinux_gate": "production",
        }
        for key, expected in required.items():
            if info.get(key) != expected:
                raise SystemExit(
                    f"production host build requires build-info {key}={expected}"
                )
        if not imx8mm_targets[0].endswith("-user"):
            raise SystemExit("production host build rejects Android userdebug")

    print(
        f"Android provenance accepted for {args.release_mode}: {imx8mm_targets[0]}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

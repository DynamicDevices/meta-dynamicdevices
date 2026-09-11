#!/usr/bin/env python3
"""Project BitBake -e output to stable policy values with assignment history."""

from __future__ import annotations

import re
import sys
from pathlib import Path


EXACT = {
    "BBMASK", "CORE_IMAGE_BASE_INSTALL", "CORE_IMAGE_EXTRA_INSTALL",
    "DISTRO", "DISTRO_FEATURES", "IMAGE_BOOT_FILES", "IMAGE_FEATURES",
    "IMAGE_FSTYPES", "IMAGE_INSTALL", "IMAGE_ROOTFS_EXTRA_SPACE",
    "IMAGE_ROOTFS_SIZE", "INITRAMFS_FSTYPES", "INITRAMFS_IMAGE",
    "INITRAMFS_MAXSIZE", "MACHINE", "MACHINE_FEATURES",
    "PACKAGE_INSTALL", "SDKIMAGE_FEATURES", "TOOLCHAIN_TARGET_TASK",
    "WKS_FILE",
}
PREFIXES = (
    "FIT_", "KERNEL_", "OPTEE_", "OSTREE_", "PREFERRED_PROVIDER_",
    "PREFERRED_VERSION_", "SOTA_", "UBOOT_",
)
ASSIGNMENT = re.compile(r'^([A-Za-z0-9_${}/:.+-]+)=')


def selected(name: str) -> bool:
    return name in EXACT or name.startswith(PREFIXES)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} BITBAKE_ENV", file=sys.stderr)
        return 2
    comments: list[str] = []
    for line in Path(sys.argv[1]).read_text(errors="replace").splitlines():
        if line.startswith("#"):
            comments.append(line)
            continue
        match = ASSIGNMENT.match(line)
        if match and selected(match.group(1)):
            print("\n".join(comments[-40:]))
            print(line)
        comments.clear()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

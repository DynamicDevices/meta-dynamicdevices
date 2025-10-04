# Large Binary Files - Not Tracked in Git

This directory contains large binary files that are excluded from Git tracking to keep repository size manageable.

## Contents

### Boot Files
- **`imx-boot-mfgtool`** - Manufacturing bootloader (219KB)
- **`u-boot-mfgtool.itb`** - Manufacturing U-Boot (1.3MB)

## Purpose

These files serve as known-good bootloaders for:
- **Board recovery** when cloud builds have broken mfgtools
- **Development testing** with stable bootloader versions
- **Custom configurations** for specific board requirements

## Usage

See [custom-boot-files/README.md](README.md) for detailed usage instructions.

## Git LFS Consideration

For production repositories, consider using Git LFS (Large File Storage) for binary files:

```bash
# Install Git LFS
git lfs install

# Track binary files
git lfs track "*.itb"
git lfs track "*mfgtool*"

# Add and commit normally
git add .gitattributes
git commit -m "Add Git LFS tracking for binary files"
```

## File Sources

These files originate from known-working Foundries.io builds and should be updated when stable builds are confirmed.

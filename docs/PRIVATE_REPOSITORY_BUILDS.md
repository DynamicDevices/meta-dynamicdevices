# Private Repository Builds - Quick Reference

This document provides a quick reference for building with private repositories in the meta-dynamicdevices layer.

## Quick Setup

```bash
# 1. Ensure SSH agent is running
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# 2. Test GitHub access
ssh -T git@github.com

# 3. Build (SSH keys forwarded automatically)
KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh
```

## Affected Recipes

| Recipe | Repository | Machine Feature |
|--------|------------|-----------------|
| `eink-spectra6` | `DynamicDevices/eink-spectra6` | `el133uf1` |
| `spi-lib` | `DynamicDevices/spi-lib` | Various |

## Troubleshooting

### Common Error: "Host key verification failed"
```bash
# This is handled automatically by kas-container --ssh-agent
# No action needed if SSH agent is properly configured
```

### Common Error: "Permission denied (publickey)"
```bash
# Check SSH agent
echo $SSH_AUTH_SOCK
ssh-add -l

# Test GitHub access
ssh -T git@github.com
```

### Debug in Container
```bash
# Enter container shell
./scripts/kas-shell-base.sh

# Test SSH in container
ssh -T git@github.com
```

## Build Scripts

All build scripts automatically handle SSH forwarding:

- `./scripts/kas-build-base.sh` - Basic build
- `./scripts/kas-shell-base.sh` - Interactive shell
- `./scripts/kas-build-base-enhanced.sh` - Advanced build with options

## Technical Details

The scripts use kas-container's built-in SSH support:
- `--ssh-agent` - Forwards SSH agent
- `--ssh-dir ~/.ssh` - Mounts SSH directory

## See Also

- [Complete Guide: Building with Private Repositories](../wiki/Building-with-Private-Repositories.md)
- [Main README: Building from Source](../README.md#building-from-source)
- [KAS Documentation](https://kas.readthedocs.io/en/latest/userguide.html#container-usage)

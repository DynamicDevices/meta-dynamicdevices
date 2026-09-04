# Jaguar Screen galcore rollback baseline — 2026-09-04

This release preserves the last i.MX8MM Jaguar Screen configuration before the
Waydroid graphics stack is changed from NXP galcore/imx-gpu-viv to Mesa
Etnaviv.

## Release identity

- Release tag: `jaguar-screen-galcore-baseline-2026.09.04`
- Foundries factory: `dynamic-devices`
- Machine: `imx8mm-jaguar-screen`
- Hardware-lab device: `imx8mm-jaguar-screen-2210a09dab86563`
- Hardware rollback target: Foundries target `2838`
- Tagged source release build: Foundries target `2840`
- Target 2840 OSTree: `0008cdaca80b08c524d6db29df02c6c168382ea9e8de07814083380a04d36ea2`
- BSP submodule: `88b8e2706814622476f0eac962935f4888df7af7`
- Distro submodule: `ef0bb9b09a72480e30507e9807d684aea8e98400`

The manifest and CI repositories carry the same release tag. Their tagged
revisions are the authoritative source assembly and build configuration.

## Known state

- The host display is operational through `imx-drm` with NXP's proprietary
  `galcore`, `imx-gpu-viv`, EGL/GBM and Weston G2D renderer stack.
- Waydroid 1.4.2 and its Android 13 system/vendor images are installed on the
  hardware target.
- Binder support and the Android container start correctly.
- Waydroid graphics do **not** boot to a usable Android UI in this release.
  The generic Android vendor image uses Mesa Etnaviv, which cannot allocate
  buffers through the host's galcore DRM device. SurfaceFlinger aborts with
  `Failed to allocate buffer` / `output buffer not gpu writeable`.
- Android images are provisioned into `/var/lib/waydroid/images` rather than
  included in the OSTree payload.

## Rollback

Prefer an OTA rollback of the hardware-lab device to Foundries target `2840`,
which was built from the tagged manifest commit. Target `2838` remains the
known-running pre-release hardware fallback.
For a source rollback, check out this tag in `meta-dynamicdevices`,
`lmp-manifest`, and `ci-scripts`, then build the tagged manifest without any
Etnaviv experiment commits.

Do not describe target 2838 as an Etnaviv or accelerated-Waydroid target: it is
the deliberately retained galcore baseline.

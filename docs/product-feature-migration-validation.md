# Product-feature migration validation

Validation date: 2026-09-02

This records local evidence for migration to the canonical
`lmp-dynamicdevices` distro. It is not approval to publish factory pins or to
retire compatibility distro files.

## Effective feature parity

| Product | Legacy selection | Canonical `DD_PRODUCT_FEATURES` | Result |
| --- | --- | --- | --- |
| Jaguar Sentai | `lmp-dynamicdevices-headless` | `improv` | Same effective `DISTRO_FEATURES` token set |
| Jaguar DT510 | `lmp-dynamicdevices-headless` | `improv usb-gadget` | Same effective token set; legacy comments mention ALSA but the effective configuration removes it |
| Jaguar Screen | legacy screen-enabled headless configuration | `display flutter godot` | Same effective display/UI/audio token set; deliberately no Improv |
| Android/Waydroid products | `lmp-dynamicdevices-headless-waydroid` | `android-container` | Preserves Wayland, OpenGL, PulseAudio and ALSA; adds Vulkan because the current Waydroid recipe requires it |

Headless operation was also checked with an empty feature selection. It omits
display, UI, audio-runtime, Android and Improv software features. Hardware
capabilities such as Bluetooth remain in `MACHINE_FEATURES` and do not select
product software.

## Compatibility checks

- Unknown product-feature names fail at `ConfigParsed`.
- `display`, `flutter` and `godot` fail unless the machine declares
  `display-multimedia`.
- Selecting `display` on `imx8mm-jaguar-sentai` was verified to fail.
- Standalone `audio` was verified to expand to ALSA and PulseAudio.
- `imx8mm-jaguar-screen` declares `display-multimedia` in the BSP.

## Dependency proofs

- `imx8mm-jaguar-screen`, `display flutter godot`:
  `bitbake -n lmp-factory-image` completed all 9,463 tasks successfully.
- `imx95-frdm-evk`, `android-container`:
  `bitbake -n lmp-factory-image` completed all 7,722 tasks successfully.
- The Android check also proved that removing Vulkan makes `waydroid`
  unbuildable because its recipe lists Vulkan in `REQUIRED_DISTRO_FEATURES`.

No prior rootfs package manifests were present in the local worktrees, so a
package-by-package manifest comparison is not claimed. Effective feature-set
comparison and complete dry-run dependency graphs are the available local
evidence.

## Rollout gates still required

Validated local rollout candidates (all worktrees clean when recorded):

| Repository/worktree | Commit |
| --- | --- |
| `meta-dynamicdevices-bsp` | `3e2d741a7829` |
| `meta-dynamicdevices-distro` | `ea70a12` |
| Foundries `ci-scripts` | `53e954882c97` |
| AESL `factory-core-ci` | `33b25f2d8b6e` |
| AESL Factory Definition | `379727319ef4` |

Publish dependencies before their consumers: distro and BSP first,
superproject next, then Foundries/AESL configuration and manifest pins.

1. Publish the distro, BSP, superproject, Foundries Factory Definition and
   AESL runner/config branches in dependency order.
2. Update public/private manifest pins to the published commits. Private-source
   pin changes and CI triggers require the physical hardware-key touch.
3. Build deployable images and retain their rootfs/package manifests as the new
   baselines.
4. Boot and exercise the Screen and Android targets on hardware, including
   display/touch, Flutter, Godot, Waydroid, audio where selected, OTA identity
   and rollback-sensitive behavior.
5. Confirm no live factory, manifest or local build consumer names a legacy
   distro; only then delete the compatibility distro files.

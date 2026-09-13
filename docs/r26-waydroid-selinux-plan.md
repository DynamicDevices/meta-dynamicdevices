# R26 Waydroid host SELinux adoption and verification

Status: implementation in progress; not release-approved.

## Objective

Run Waydroid on the 2 GB i.MX8MM Jaguar Screen with the Foundries/LmP host
SELinux policy enforcing. Android retains only the changes needed to operate
inside LXC because SELinux is kernel-global and cannot be independently owned
by the Android userspace in that container.

## Reproducible baseline

- Published Foundries target: `2892` (`main-jaguar-screen`)
- Manifest: `361d5ac577d9a9714069f689f4ed04680834f1e3`
- Application layer: `306e43cd04a93f42c0bd195601fa261045da39f0`
- BSP layer: `c6be3be6d94a5492b534b173f44e65592b49a13e`
- Distro layer: `c635979548a155f6035325b328ab9bd7a7a2ce24`
- LmP/meta-lmp: `d176612d7fc811bb8f511fcaa06dc617513c0eb5`
- meta-selinux candidate: `48f745109a1ecea9afe2a74d41dbd90fa7b370af`
- Android container-awareness change: `a9c4291`
- Android validation run: `34748284172`

## Layer-adoption audit

The candidate meta-selinux revision declares Scarthgap compatibility and
depends on OE-Core plus meta-python; the existing manifest already supplies
meta-oe. It is inert unless `selinux` is present in `DISTRO_FEATURES`.

The layer changes recipes globally once enabled, including systemd, D-Bus,
OpenSSH, sudo, util-linux and Mesa. The upstream reference policy explicitly
requires product tailoring. Its kernel append only targets `linux-yocto`, so
the Jaguar `linux-lmp-fslc-imx` kernel requires its own fragment.

Adoption is scoped through the product contract. `android-container` implies
the standard `selinux` distro feature; an explicit `host-selinux` product
feature is also available for future non-Android products. mfgtool tuples do
not select either feature.

The custom refpolicy append is a dynamic append: it is parsed only when the
`selinux` layer collection is present. `APPS_MODS=waydroid` is required because
new refpolicy modules otherwise default to `off` when absent from the upstream
`modules.conf`.

## Development policy lifecycle

The first hardware image keeps the host globally enforcing but declares only
`waydroid_t` permissive. This isolates policy discovery to the Waydroid domain
and avoids weakening unrelated host services. The statement
`permissive waydroid_t;` is a release blocker and must be removed after AVCs
have been classified and converted to narrow rules.

Immutable OSTree content is labelled at image construction with
`selinux-image`. `FIRST_BOOT_RELABEL` remains disabled because a whole-root
relabel is unsuitable for an immutable deployment. The provisioning unit runs
`restorecon -RF /var/lib/waydroid` to migrate persistent state retained across
OTA; the existing network script restores the `/run/waydroid-lxc` context.

Device nodes shared with host services are not relabelled as Waydroid-owned.
Access to Binder, DRM/Etnaviv, V4L2 and the Weston/PulseAudio sockets will be
granted against their host-owned types from reviewed hardware AVC evidence.
Android system/vendor files carry Android policy xattrs that are not valid
host-policy types, so Waydroid applies the single host-owned
`waydroid_rootfs_t` mount context to its ext4 and overlay mounts whenever host
SELinux is active. This avoids any release rule permitting execution from the
generic `unlabeled_t` type.

## Existing CI tuple regression matrix

The layer-adoption gate covers every active `ci-scripts` platform tuple, not
only the new Jaguar Screen image.

| Platform ref | Machine | Platform distro/special case | Existing mfgtool tuple |
| --- | --- | --- | --- |
| `main-jaguar` | `imx8mm-jaguar-sentai` | default | yes |
| `main-jaguar-sentai` | `imx8mm-jaguar-sentai` | headless, signed/LUKS/OCF parameters | yes |
| `main-jaguar-sentai-prod` | `imx8mm-jaguar-sentai` | production | yes |
| `main-jaguar-sentai-ext` | `imx8mm-jaguar-sentai` | default | yes |
| `main-jaguar-sentai-ce` | `imx8mm-jaguar-sentai` | CE image | yes |
| `main-jaguar-sentai-ocf` | `imx8mm-jaguar-sentai` | headless, signed/LUKS/OCF | yes |
| `imx8mm-jaguar-handheld-5in` | `imx8mm-jaguar-handheld-5in` | legacy Waydroid distro | yes |
| `imx8mm-jaguar-handheld-7in` | `imx8mm-jaguar-handheld-7in` | legacy Waydroid distro | yes |
| `main-jaguar-phasora` | `imx8mm-jaguar-phasora` | headless | yes |
| `main-jaguar-phasora-ext` | `imx8mm-jaguar-phasora` | headless | yes |
| `main-imx8ulp` | `imx8ulp-lpddr4-evk` | headless | yes |
| `main-jaguar-inst` | `imx8mm-jaguar-inst` | headless | yes |
| `main-rpi4` | `raspberrypi4-64` | default | no |
| `main-rpi4-v2g-evse` | `raspberrypi4-64` | legacy Waydroid distro | no |
| `main-rpi5` | `raspberrypi5` | default | no |
| `main-imx93-jaguar-eink` | `imx93-jaguar-eink` | headless, signed/LUKS | yes |
| `main-imx95-frdm-devel` | `imx95-frdm-evk` | product-feature Android | yes |
| `main-jaguar-screen` | `imx8mm-jaguar-screen` | `display android-container` | none currently defined |

## Gates before manifest publication

### Completed exact-pin preflight evidence

- `kas checkout kas/r26-jaguar-screen-selinux.yml` resolved all candidate
  layers at their recorded SHAs and parsed 4,172 recipes with zero errors.
- `bitbake -g refpolicy-targeted` proves the policy recipe has no target
  compiler or libc dependency; it uses only its declared host-native policy
  tools (`INHIBIT_DEFAULT_DEPS = "1"`).
- `bitbake refpolicy-targeted -c compile` completed all 459 tasks. The generated
  `policy/modules.conf` contains `waydroid = module` and the build produced
  `waydroid.pp` (114,378 bytes), proving the custom module is compiled rather
  than merely present in `SRC_URI`.

The full image, kernel configuration, adoption matrix, Foundries build and
physical-board gates remain open; this recipe proof does not substitute for
them.

1. Resolve the exact candidate manifest and prove every project SHA exists.
2. Parse the Jaguar Screen platform and mfgtool configurations.
3. Run `bitbake-layers show-layers`, `show-appends`, and provider checks.
4. Run kernel `do_kernel_configcheck`; prove SELinux is built in and appears
   in `CONFIG_LSM` only for the selected product.
5. Build the policy and rootfs locally; prove the Waydroid module is active,
   `/etc/selinux/config` says enforcing, and OSTree preserves labels.
6. Parse/build the full platform and mfgtool regression matrix above, including
   bootloader, kernel, OP-TEE, signing and recovery/factory artifacts.
7. Verify SBOM, licence manifest, source hashes and image hashes are retained.
8. Only then pin the three Dynamic Devices layer commits in the manifest and
   submit the Foundries build.

## Hardware acceptance

- `getenforce` reports `Enforcing`; kernel command line does not disable it.
- Waydroid processes enter `waydroid_t`; no Waydroid process remains
  `unconfined_t`, `init_t`, or another generic domain.
- The release policy contains no permissive domains and no unexplained AVCs.
- Android boots, Binder works, kiosk UI renders, and 2 GB zram/low-memory
  settings are active.
- Etnaviv acceleration and V4L2 H.264 decode are demonstrated independently.
- Foundries OTA install and rollback both succeed without breaking labels,
  secure boot, recovery or manufacturing flows.

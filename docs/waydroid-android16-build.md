# AESL Android 16 Waydroid host build

The i.MX8MM product deliberately refuses to reuse the recipe's legacy
LineageOS 18.1 payload. Build the reviewed LineageOS 23.2 manifest first; its
artifact root contains raw `imx8mm/system.img`, `imx8mm/vendor.img`, the SPDX
JSON SBOM, immutable source manifest, build metadata, and a generated
`waydroid-images.inc` containing their exact hashes.

All persistent source trees, downloads, caches, build outputs, and large CI
artifacts must remain on the dedicated `/yocto` volume. On the self-hosted
runner, build the host image with:

```sh
AESL_ANDROID_ARTIFACT_DIR=/yocto/android-16-artifacts/RUN-ATTEMPT \
AESL_YOCTO_WORK_ROOT=/yocto/waydroid-host \
KAS_WORK_DIR=/yocto/waydroid-host/kas-work \
KAS_BUILD_DIR=/yocto/waydroid-host/kas-build \
  kas build kas/waydroid-imx8mm-aesl.yml
```

The KAS profile rejects artifact and work paths outside `/yocto`; `waydroid-data`
rejects absent or malformed SHA-256 pins and installs the SBOM, source lock,
and build metadata as release evidence alongside the chunked images.
The proof profile also re-enables OpenEmbedded SPDX generation and copies the
host package licence manifest and licence texts into the image. CI fails unless
the deploy directory contains the host image manifest and SPDX archive, so the
Android SBOM is not mistaken for a complete product SBOM.

The host workflow defaults to `integration` mode so a reviewed Android
`userdebug` artifact can be exercised on the board. Select `production` only
with an Android `user` artifact whose `build-info.json` records both production
release class and the blocking SELinux production gate; the workflow rejects
missing or integration-only provenance.

CI runs this inside the digest-pinned Yocto build container with `/yocto`
mounted at the same absolute path. Do not substitute `kas-container` without
also arranging that mount and explicitly forwarding the AESL variables.

## Host container security gate

The `android-container` product feature also enables the AppArmor distro
feature. The Jaguar kernel builds AppArmor into its ordered LSM list, and the
Waydroid recipe installs all three upstream profiles in enforce mode. Image
provisioning waits for `apparmor.service`; if the `lxc-waydroid` profile is not
loaded, the generated LXC configuration remains unconfined and the runtime
verification must fail.

The patched, pinned Waydroid 1.6.3 runtime writes a deny-by-default LXC device
policy. It then grants `rwm` only to fixed pseudo devices and the exact major
and minor numbers of bind-mounted character devices. The product provisioner
separately limits mounts to the chosen Etnaviv render node, approved DMA heaps,
and the capability-selected NXP decoder. The GPU and heaps are `root:1003`
(`AID_GRAPHICS`) mode `0660`; the decoder is `root:1013` (`AID_MEDIA`) mode
`0660`. No block-device or wildcard device grant is generated.

On the target, run:

```sh
sudo /usr/libexec/waydroid-acceleration-check
```

This is a release gate: it checks AppArmor is enabled and enforcing, the LXC
profile is selected, the device policy is deny-by-default with exact rules,
and the Android GPU/Vulkan/Codec2 runtime state matches the product contract.

Record the complete target snapshots and restart proof with:

```sh
sudo /usr/libexec/waydroid-board-evidence capture
sudo /usr/libexec/waydroid-board-evidence restart
```

Suspend/resume is a two-stage test so the evidence survives the SSH session
dropping during suspend:

```sh
sudo /usr/libexec/waydroid-board-evidence suspend-prepare /var/log/waydroid-validation/suspend-1
# Suspend and wake the board using the product wake source.
sudo /usr/libexec/waydroid-board-evidence suspend-verify /var/log/waydroid-validation/suspend-1
```

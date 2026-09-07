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

CI runs this inside the digest-pinned Yocto build container with `/yocto`
mounted at the same absolute path. Do not substitute `kas-container` without
also arranging that mount and explicitly forwarding the AESL variables.

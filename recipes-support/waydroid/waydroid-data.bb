SUMMARY = "Waydroid uses a container-based approach to boot a full Android system"
DESCRIPTION = "Android image file for Waydroid"
# This is the packaging recipe's licence, not a claim that every component in
# a prebuilt Android filesystem has one licence. The AESL Android 16 payload
# carries its SPDX SBOM and immutable source manifest as installed evidence.
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/BSD-3-Clause;md5=550794465ba0ec5312d6919e203a55f9"
LICENSE:imx8mm-jaguar-screen = "CLOSED"
LIC_FILES_CHKSUM:imx8mm-jaguar-screen = ""
PV:imx8mm-jaguar-screen = "16.0+lineage23.2"

# works only for following 4 archs
COMPATIBLE_MACHINE ?= "(^$)"
COMPATIBLE_MACHINE:x86-64 = "(.*)"
COMPATIBLE_MACHINE:armv7a = "(.*)"
COMPATIBLE_MACHINE:armv7ve = "(.*)"
COMPATIBLE_MACHINE:aarch64 = "(.*)"

WAYDROID_ARCH:x86-64 = "waydroid_x86_64"
WAYDROID_ARCH:aarch64 = "waydroid_arm64"
WAYDROID_SYSTEM_IMAGE = "lineage-18.1-20231028-VANILLA-${WAYDROID_ARCH}-system.zip"
WAYDROID_VENDOR_IMAGE = "lineage-18.1-20231028-MAINLINE-${WAYDROID_ARCH}-vendor.zip"
WAYDROID_VENDOR_IMAGE:halium = "lineage-18.1-20231028-HALIUM_11-${WAYDROID_ARCH}-vendor.zip"

SHA256SUM_SYSTEM:x86-64 = "992853ed6849fd26cb750d880016ff605910661229fb3ab22447a7e6f1c8c112"
SHA256SUM_VENDOR:x86-64 = "c0057b233c5dddf7b8f3bb046d3114fa34589c776743ced61840615d4d48f5bc"

SHA256SUM_SYSTEM:aarch64 = "406adff7e346eab019a51287e49765a6d6c24d62c0a47eb74eb8ea9ad2c384ee"
SHA256SUM_VENDOR:aarch64 = "e67f0d92907bd74083f1f83da701609c94c4cdbd8ba7c662c27d3e94194aac70"

SHA256SUM_VENDOR:halium = "cd5b1394f35c97c0284f365e52588eecd7b89b6aa28624aefca55aff509143e5"

# The Android image workflow emits waydroid-images.inc with these exact
# values. The consuming KAS configuration must also prepend the artifact's
# imx8mm and root directories to FILESEXTRAPATHS for this recipe.
AESL_WAYDROID_SYSTEM_SHA256 ?= ""
AESL_WAYDROID_VENDOR_SHA256 ?= ""
AESL_WAYDROID_SBOM_SHA256 ?= ""
AESL_WAYDROID_SOURCE_MANIFEST_SHA256 ?= ""
AESL_WAYDROID_BUILD_INFO_SHA256 ?= ""

SHA256SUM_SYSTEM:imx8mm-jaguar-screen = "${AESL_WAYDROID_SYSTEM_SHA256}"
SHA256SUM_VENDOR:imx8mm-jaguar-screen = "${AESL_WAYDROID_VENDOR_SHA256}"

SRC_URI = "https://sourceforge.net/projects/waydroid/files/images/system/lineage/${WAYDROID_ARCH}/${WAYDROID_SYSTEM_IMAGE};name=system \
           https://sourceforge.net/projects/waydroid/files/images/vendor/${WAYDROID_ARCH}/${WAYDROID_VENDOR_IMAGE};name=vendor \
           "
SRC_URI:imx8mm-jaguar-screen = " \
    file://system.img;name=system \
    file://vendor.img;name=vendor \
    file://sbom.spdx.json;name=sbom \
    file://source-manifest.xml;name=source-manifest \
    file://build-info.json;name=build-info \
"

SRC_URI[system.sha256sum] = "${SHA256SUM_SYSTEM}"
SRC_URI[vendor.sha256sum] = "${SHA256SUM_VENDOR}"
SRC_URI[sbom.sha256sum] = "${AESL_WAYDROID_SBOM_SHA256}"
SRC_URI[source-manifest.sha256sum] = "${AESL_WAYDROID_SOURCE_MANIFEST_SHA256}"
SRC_URI[build-info.sha256sum] = "${AESL_WAYDROID_BUILD_INFO_SHA256}"

python __anonymous() {
    if d.getVar("MACHINE") != "imx8mm-jaguar-screen":
        return
    if "waydroid" not in (d.getVar("DISTRO_FEATURES") or "").split():
        return
    required = (
        "AESL_WAYDROID_SYSTEM_SHA256",
        "AESL_WAYDROID_VENDOR_SHA256",
        "AESL_WAYDROID_SBOM_SHA256",
        "AESL_WAYDROID_SOURCE_MANIFEST_SHA256",
        "AESL_WAYDROID_BUILD_INFO_SHA256",
    )
    for name in required:
        value = d.getVar(name) or ""
        if len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
            bb.fatal("%s must be supplied by the reviewed Android 16 artifact include" % name)
}

do_install() {
    install -dm755 "${D}/usr/share/waydroid-extra/images"

    # split files up
    split -b100M -d ${WORKDIR}/system.img ${WORKDIR}/system.img.
    split -b100M -d ${WORKDIR}/vendor.img ${WORKDIR}/vendor.img.

    # The upstream archives unpack to these names; the AESL Android 16 inputs
    # are already raw images. Both paths are chunked to keep OSTree objects
    # manageable on constrained devices.
    for f in ${WORKDIR}/system.img.*; do \
        install -m 0644 "$f" "${D}/usr/share/waydroid-extra/images"; \
    done
    for f in ${WORKDIR}/vendor.img.*; do \
        install -m 0644 "$f" "${D}/usr/share/waydroid-extra/images"; \
    done
}

do_install:append:imx8mm-jaguar-screen() {
    install -dm0755 "${D}/usr/share/waydroid-extra/evidence"
    install -m 0644 "${WORKDIR}/sbom.spdx.json" \
        "${D}/usr/share/waydroid-extra/evidence/sbom.spdx.json"
    install -m 0644 "${WORKDIR}/source-manifest.xml" \
        "${D}/usr/share/waydroid-extra/evidence/source-manifest.xml"
    install -m 0644 "${WORKDIR}/build-info.json" \
        "${D}/usr/share/waydroid-extra/evidence/build-info.json"
    printf '%s  system.img\n%s  vendor.img\n' \
        "${AESL_WAYDROID_SYSTEM_SHA256}" "${AESL_WAYDROID_VENDOR_SHA256}" \
        > "${D}/usr/share/waydroid-extra/evidence/IMAGE_SHA256SUMS"
}

FILES:${PN} += "/usr/share/waydroid-extra/images /usr/share/waydroid-extra/evidence"

pkg_postinst_ontarget:${PN} () {
  #!/bin/sh
  echo Rebuilding Waydroid OS images
  mkdir -p /etc/waydroid-extra/images
  cat /usr/share/waydroid-extra/images/system.img.* > /etc/waydroid-extra/images/system.img
#  rm /usr/share/waydroid-extra/images/system.img.*
  cat /usr/share/waydroid-extra/images/vendor.img.* > /etc/waydroid-extra/images/vendor.img
#  rm /usr/share/waydroid-extra/images/vendor.img.*
  if [ -s /usr/share/waydroid-extra/evidence/IMAGE_SHA256SUMS ]; then
    (cd /etc/waydroid-extra/images && \
      sha256sum -c /usr/share/waydroid-extra/evidence/IMAGE_SHA256SUMS)
  fi
}

# QA Skip Justification: Waydroid packages pre-built Android system images
# which contain binaries for different architectures and complex dependencies
# that cannot be analyzed by standard Yocto QA checks
INSANE_SKIP:${PN} += "arch file-rdeps"

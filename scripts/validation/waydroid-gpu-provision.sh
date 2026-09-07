#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
provision=${repo_root}/recipes-support/waydroid/waydroid/waydroid-image-provision
test_root=$(mktemp -d /tmp/waydroid-gpu-provision.XXXXXX)
trap 'rm -rf "${test_root}"' EXIT HUP INT TERM

mkdir -p "${test_root}/images" \
    "${test_root}/sys/class/drm/renderD128/device" \
    "${test_root}/dev/dri"
printf 'image\n' > "${test_root}/images/system.img"
printf 'image\n' > "${test_root}/images/vendor.img"
printf 'DRIVER=etnaviv\n' > "${test_root}/sys/class/drm/renderD128/device/uevent"
printf '[waydroid]\narch = arm64\n\n[properties]\nro.hardware.vulkan = lvp\n' \
    > "${test_root}/waydroid.cfg"

WAYDROID_IMAGES_DIR=${test_root}/images \
WAYDROID_CONFIG=${test_root}/waydroid.cfg \
WAYDROID_SYS_DRM_DIR=${test_root}/sys/class/drm \
WAYDROID_DEV_DRI_DIR=${test_root}/dev/dri \
WAYDROID_ALLOW_FAKE_DRM=1 \
    sh "${provision}"

config=${test_root}/waydroid.cfg
grep -Fqx 'drm_device = '"${test_root}"'/dev/dri/renderD128' "${config}"
grep -Fqx 'gralloc.gbm.device = '"${test_root}"'/dev/dri/renderD128' "${config}"
grep -Fqx 'ro.hardware.egl = mesa' "${config}"
grep -Fqx 'ro.hardware.gralloc = minigbm_gbm_mesa' "${config}"
grep -Fqx 'ro.hardware.hwcomposer = waydroid' "${config}"
grep -Fqx 'ro.opengles.version = 196609' "${config}"
if grep -Fq 'ro.hardware.vulkan' "${config}"; then
    echo 'Vulkan fallback was not removed' >&2
    exit 1
fi

echo 'Waydroid Etnaviv GPU provisioning: passed'

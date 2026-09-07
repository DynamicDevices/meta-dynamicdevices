#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
provision=${repo_root}/recipes-support/waydroid/waydroid/waydroid-image-provision
test_root=$(mktemp -d /tmp/waydroid-gpu-provision.XXXXXX)
trap 'rm -rf "${test_root}"' EXIT HUP INT TERM

mkdir -p "${test_root}/images" \
    "${test_root}/sys/class/drm/renderD128/device" \
    "${test_root}/sys/class/video4linux/video2" \
    "${test_root}/dev/dri" \
    "${test_root}/dev/dma_heap"
printf 'image\n' > "${test_root}/images/system.img"
printf 'image\n' > "${test_root}/images/vendor.img"
printf 'DRIVER=etnaviv\n' > "${test_root}/sys/class/drm/renderD128/device/uevent"
printf 'heap\n' > "${test_root}/dev/dma_heap/system"
printf 'heap\n' > "${test_root}/dev/dma_heap/linux,cma"
printf 'vsi_v4l2dec\n' > "${test_root}/sys/class/video4linux/video2/name"
printf 'video\n' > "${test_root}/dev/video2"
printf '[waydroid]\narch = arm64\nimages_path = %s/images\n\n[properties]\nro.hardware.vulkan = lvp\n' \
    "${test_root}" > "${test_root}/waydroid.cfg"

WAYDROID_CONFIG=${test_root}/waydroid.cfg \
WAYDROID_SYS_DRM_DIR=${test_root}/sys/class/drm \
WAYDROID_DEV_DRI_DIR=${test_root}/dev/dri \
WAYDROID_DEV_DMA_HEAP_DIR=${test_root}/dev/dma_heap \
WAYDROID_SYS_VIDEO_DIR=${test_root}/sys/class/video4linux \
WAYDROID_DEV_VIDEO_DIR=${test_root}/dev \
WAYDROID_ALLOW_FAKE_DRM=1 \
    sh "${provision}"

config=${test_root}/waydroid.cfg
grep -Fqx 'drm_device = '"${test_root}"'/dev/dri/renderD128' "${config}"
grep -Fqx 'dma_heap_devices = /dev/dma_heap/system;/dev/dma_heap/linux,cma' "${config}"
grep -Fqx 'video_devices = /dev/video2' "${config}"
grep -Fqx 'gralloc.gbm.device = '"${test_root}"'/dev/dri/renderD128' "${config}"
grep -Fqx 'ro.hardware.egl = mesa' "${config}"
grep -Fqx 'ro.hardware.gralloc = minigbm_gbm_mesa' "${config}"
grep -Fqx 'ro.hardware.hwcomposer = waydroid' "${config}"
grep -Fqx 'ro.opengles.version = 196609' "${config}"
if grep -Fq 'ro.hardware.vulkan' "${config}"; then
    echo 'Vulkan fallback was not removed' >&2
    exit 1
fi

printf '%s\n' \
    'lxc.cgroup2.devices.deny = a' \
    "lxc.mount.entry = ${test_root}/dev/dri/renderD128 dev/dri/renderD128 none bind,create=file 0 0" \
    'lxc.mount.entry = /dev/dma_heap/system dev/dma_heap/system none bind,create=file 0 0' \
    'lxc.mount.entry = /dev/dma_heap/linux,cma dev/dma_heap/linux,cma none bind,create=file 0 0' \
    'lxc.mount.entry = /dev/video2 dev/video2 none bind,create=file 0 0' \
    > "${test_root}/config_nodes"

printf '%s\n' \
    '#!/bin/sh' \
    'case "$*" in' \
    '  status) echo "Container: RUNNING" ;;' \
    '  "shell getprop ro.hardware.egl") echo mesa ;;' \
    '  "shell getprop ro.hardware.gralloc") echo minigbm_gbm_mesa ;;' \
    '  "shell getprop ro.hardware.vulkan") : ;;' \
    '  "shell pm list features") echo feature:android.hardware.opengles.aep ;;' \
    '  "shell dumpsys SurfaceFlinger") echo "GLES: Mesa etnaviv GC7000Lite" ;;' \
    '  "shell dumpsys media.codec") echo c2.v4l2.avc.decoder ;;' \
    '  *) exit 1 ;;' \
    'esac' > "${test_root}/waydroid"
chmod 0755 "${test_root}/waydroid"

WAYDROID_CONFIG=${config} \
WAYDROID_LXC_NODES=${test_root}/config_nodes \
WAYDROID_SYS_DRM_DIR=${test_root}/sys/class/drm \
WAYDROID_BIN=${test_root}/waydroid \
WAYDROID_ALLOW_FAKE_DEVICES=1 \
    sh "${repo_root}/recipes-support/waydroid/waydroid/waydroid-acceleration-check"

echo 'Waydroid Etnaviv GPU and V4L2 provisioning: passed'

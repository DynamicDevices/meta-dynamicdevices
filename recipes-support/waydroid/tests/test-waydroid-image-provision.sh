#!/bin/sh
# Host-side regression tests for the immutable FRDM image provisioning.

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
provision=${here}/../waydroid/waydroid-image-provision
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT HUP INT TERM

mkdir -p "${work}/bin" "${work}/output"

cat >"${work}/bin/waydroid" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>/tmp/test-output/waydroid.log
printf '[waydroid]\n' >/var/lib/waydroid/waydroid.cfg
EOF

cat >"${work}/bin/curl" <<'EOF'
#!/bin/sh
output=
while [ "$#" -gt 0 ]; do
    if [ "$1" = --output ]; then
        shift
        output=$1
    fi
    shift
done
case "${output}" in
    */system.img) printf 'new-system-image\n' >"${output}" ;;
    */vendor.img) printf 'new-vendor-image\n' >"${output}" ;;
    *) exit 2 ;;
esac
EOF

chmod 0755 "${work}/bin/waydroid" "${work}/bin/curl"

write_release() {
    release=$1
    system_hash=$2
    vendor_hash=$3
    cat >"${release}" <<EOF
WAYDROID_IMAGE_RELEASE=test-release
WAYDROID_IMAGE_BASE_URL=https://invalid.example/test-release
WAYDROID_SYSTEM_SHA256=${system_hash}
WAYDROID_VENDOR_SHA256=${vendor_hash}
WAYDROID_SOURCE_LOCK_SHA256=test-source-lock
EOF
}

run_provision() {
    state=$1
    installed=$2
    share=$3
    : >"${work}/output/waydroid.log"
    bwrap --die-with-parent --ro-bind / / --dev /dev --proc /proc \
        --setenv PATH /usr/bin:/bin \
        --bind "${state}" /var/lib/waydroid \
        --bind "${installed}" /etc/waydroid-extra \
        --tmpfs /usr/share \
        --dir /usr/share/waydroid-extra \
        --bind "${share}" /usr/share/waydroid-extra \
        --tmpfs /tmp \
        --dir /tmp/test-output \
        --ro-bind "${work}/bin/waydroid" /usr/bin/waydroid \
        --ro-bind "${work}/bin/curl" /usr/bin/curl \
        --bind "${work}/output" /tmp/test-output \
        /bin/sh "${provision}"
}

fixture_pair() {
    images=$1
    mkdir -p "${images}"
    printf 'old-system-image\n' >"${images}/system.img"
    printf 'old-vendor-image\n' >"${images}/vendor.img"
}

old_system_hash=$(printf 'old-system-image\n' | sha256sum | cut -d' ' -f1)
old_vendor_hash=$(printf 'old-vendor-image\n' | sha256sum | cut -d' ' -f1)
new_system_hash=$(printf 'new-system-image\n' | sha256sum | cut -d' ' -f1)
new_vendor_hash=$(printf 'new-vendor-image\n' | sha256sum | cut -d' ' -f1)

# A complete installation from the current release is a no-op on reboot.
mkdir -p "${work}/case1/state" "${work}/case1/etc/images" "${work}/case1/share"
fixture_pair "${work}/case1/etc/images"
write_release "${work}/case1/share/waydroid-image-release.conf" \
    "${old_system_hash}" "${old_vendor_hash}"
cp "${work}/case1/share/waydroid-image-release.conf" \
    "${work}/case1/etc/images/release.conf"
printf '[waydroid]\n' >"${work}/case1/state/waydroid.cfg"
run_provision "${work}/case1/state" "${work}/case1/etc" "${work}/case1/share"
if [ -s "${work}/output/waydroid.log" ]; then
    printf 'unexpected Waydroid call on completed release: ' >&2
    cat "${work}/output/waydroid.log" >&2
    exit 1
fi

# Lost generated configuration reuses the matching immutable image pair.
mkdir -p "${work}/case2/state" "${work}/case2/etc/images" "${work}/case2/share"
fixture_pair "${work}/case2/etc/images"
write_release "${work}/case2/share/waydroid-image-release.conf" \
    "${old_system_hash}" "${old_vendor_hash}"
cp "${work}/case2/share/waydroid-image-release.conf" \
    "${work}/case2/etc/images/release.conf"
run_provision "${work}/case2/state" "${work}/case2/etc" "${work}/case2/share"
grep -qx 'init --images_path /etc/waydroid-extra/images --force' \
    "${work}/output/waydroid.log"

# A changed release replaces both images as one verified pair.
mkdir -p "${work}/case3/state" "${work}/case3/etc/images" "${work}/case3/share"
fixture_pair "${work}/case3/etc/images"
write_release "${work}/case3/etc/images/release.conf" \
    "${old_system_hash}" "${old_vendor_hash}"
write_release "${work}/case3/share/waydroid-image-release.conf" \
    "${new_system_hash}" "${new_vendor_hash}"
printf '[waydroid]\n' >"${work}/case3/state/waydroid.cfg"
run_provision "${work}/case3/state" "${work}/case3/etc" "${work}/case3/share"
grep -qx 'new-system-image' "${work}/case3/etc/images/system.img"
grep -qx 'new-vendor-image' "${work}/case3/etc/images/vendor.img"
cmp -s "${work}/case3/share/waydroid-image-release.conf" \
    "${work}/case3/etc/images/release.conf"
grep -qx 'init --images_path /etc/waydroid-extra/images --force' \
    "${work}/output/waydroid.log"

# A corrupt candidate fails without replacing either installed image.
mkdir -p "${work}/case4/state" "${work}/case4/etc/images" "${work}/case4/share"
fixture_pair "${work}/case4/etc/images"
write_release "${work}/case4/etc/images/release.conf" \
    "${old_system_hash}" "${old_vendor_hash}"
write_release "${work}/case4/share/waydroid-image-release.conf" \
    "${old_system_hash}" "${old_vendor_hash}"
printf '[waydroid]\n' >"${work}/case4/state/waydroid.cfg"
# Change only the selected-release marker while retaining deliberately wrong
# hashes for the mock's download.
printf 'WAYDROID_IMAGE_RELEASE=changed-release\n' >> \
    "${work}/case4/share/waydroid-image-release.conf"
if run_provision "${work}/case4/state" "${work}/case4/etc" \
        "${work}/case4/share" >"${work}/case4/failure.log" 2>&1; then
    echo 'corrupt candidate unexpectedly succeeded' >&2
    exit 1
fi
grep -q 'computed checksum did NOT match' "${work}/case4/failure.log"
grep -qx 'old-system-image' "${work}/case4/etc/images/system.img"
grep -qx 'old-vendor-image' "${work}/case4/etc/images/vendor.img"
grep -qx 'WAYDROID_IMAGE_RELEASE=test-release' \
    "${work}/case4/etc/images/release.conf"

printf 'waydroid image provisioning tests: PASS\n'

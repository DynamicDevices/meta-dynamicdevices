#!/bin/sh
# Capture read-only R26 Waydroid acceptance evidence on a Jaguar Screen board.
# shellcheck disable=SC2016 # Dollar expressions in single quotes run in sh -c.

set -eu

usage() {
    echo "usage: $0 OUTPUT_DIR [--release] [--h264 RAW_H264_FILE]" >&2
    exit 2
}

[ "$#" -ge 1 ] || usage
output_dir=$1
shift
release=0
h264_file=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --release) release=1 ;;
        --h264)
            [ "$#" -ge 2 ] || usage
            h264_file=$2
            shift
            ;;
        *) usage ;;
    esac
    shift
done

umask 077
mkdir -p "$output_dir"
summary="$output_dir/summary.tsv"
: >"$summary"

capture() {
    name=$1
    shift
    {
        echo "command: $*"
        echo "captured_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo
        "$@"
    } >"$output_dir/$name.txt" 2>&1 || true
}

record() {
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$summary"
}

expect_output() {
    check=$1
    expected=$2
    shift 2
    actual=$("$@" 2>&1 || true)
    if printf '%s\n' "$actual" | grep -Eq "$expected"; then
        record "$check" PASS "$(printf '%s' "$actual" | tr '\n\t' '  ')"
    else
        record "$check" FAIL "$(printf '%s' "$actual" | tr '\n\t' '  ')"
    fi
}

capture identity uname -a
capture os-release sh -c 'cat /etc/os-release; echo; cat /etc/lmp-version 2>/dev/null || true'
capture kernel-command-line cat /proc/cmdline
capture selinux-status sh -c 'getenforce; sestatus; semodule -lfull; semanage permissive -l 2>/dev/null || true'
capture process-contexts ps -eZ
capture waydroid-status waydroid status
capture waydroid-processes sh -c 'ps -eZ | grep -E "[w]aydroid|[l]xc" || true'
capture service-status systemctl --no-pager --full status \
    waydroid-image-provision.service waydroid-jaguar-container.service \
    waydroid-jaguar-session.service waydroid-jaguar-ui.service weston.service
capture service-journal journalctl --no-pager -b -u waydroid-image-provision.service \
    -u waydroid-jaguar-container.service -u waydroid-jaguar-session.service \
    -u waydroid-jaguar-ui.service -u weston.service
capture labels sh -c 'ls -ldZ /var/lib/waydroid /var/lib/waydroid/images /run/waydroid-lxc 2>/dev/null; matchpathcon /var/lib/waydroid /run/waydroid-lxc /usr/bin/waydroid 2>/dev/null || true'
capture device-labels sh -c 'ls -lZ /dev/binder* /dev/vndbinder* /dev/hwbinder* /dev/dri/* /dev/video* 2>/dev/null || true'
capture binder waydroid shell service list
capture surfaceflinger waydroid shell dumpsys SurfaceFlinger
capture memory sh -c 'cat /proc/meminfo; echo; cat /proc/swaps; echo; zramctl 2>/dev/null || true; echo; for z in /sys/block/zram*; do for n in disksize comp_algorithm mem_used_total; do f="$z/$n"; [ ! -e "$f" ] || { printf "%s: " "$f"; cat "$f"; }; done; done'
capture gpu sh -c 'dmesg | grep -Ei "etnaviv|galcore|drm" || true; echo; waydroid shell dumpsys SurfaceFlinger 2>/dev/null | grep -Ei "GLES|EGL|render" || true'
capture v4l2 sh -c 'v4l2-ctl --list-devices 2>/dev/null || true; echo; gst-inspect-1.0 v4l2h264dec 2>/dev/null || gst-inspect-1.0 v4l2slh264dec 2>/dev/null || true; echo; dmesg | grep -Ei "v4l2|vpu|hantro|h264" || true'
capture audio sh -c 'pactl info 2>/dev/null || wpctl status 2>/dev/null || true; echo; waydroid shell dumpsys audio 2>/dev/null || true'
capture network waydroid shell ip -brief address
capture ota-state sh -c 'aktualizr-lite status 2>/dev/null || true; echo; ostree admin status 2>/dev/null || true; echo; fw_printenv 2>/dev/null | grep -Ei "bootcount|bootlimit|rollback|upgrade_available" || true'
capture secure-boot sh -c 'dmesg | grep -Ei "secure boot|hab|ahab|caam|dm-verity|verified boot" || true'
capture image-hashes sh -c 'sha256sum /var/lib/waydroid/images/*.img 2>/dev/null || true'
capture avc-denials sh -c 'ausearch -m AVC,USER_AVC -ts boot 2>/dev/null || journalctl -k -b --no-pager | grep -Ei "avc:.*denied" || true'

expect_output host-selinux '^Enforcing$' getenforce
if grep -Eq '(^| )(selinux=0|enforcing=0)( |$)' /proc/cmdline; then
    record kernel-selinux-arguments FAIL "$(cat /proc/cmdline)"
else
    record kernel-selinux-arguments PASS "SELinux is not disabled on the kernel command line"
fi
expect_output waydroid-module '^waydroid[[:space:]]' sh -c 'semodule -lfull | grep "^waydroid[[:space:]]"'
expect_output waydroid-domain 'waydroid_t' sh -c 'ps -eZ | grep -E "[w]aydroid|[l]xc"'
expect_output binder-service-list '^[[:space:]]*[0-9]+[[:space:]]' waydroid shell service list
expect_output surfaceflinger-running 'GLES|EGL|Display' waydroid shell dumpsys SurfaceFlinger
services_ok=1
for service in waydroid-image-provision.service waydroid-jaguar-container.service \
    waydroid-jaguar-session.service waydroid-jaguar-ui.service weston.service; do
    systemctl is-active --quiet "$service" || services_ok=0
done
if [ "$services_ok" -eq 1 ]; then
    record kiosk-services PASS 'all Waydroid and Weston units are active'
else
    record kiosk-services FAIL 'one or more Waydroid/Weston units are inactive; see service-status.txt'
fi
expect_output waydroid-network 'UP|UNKNOWN' waydroid shell ip -brief address
expect_output zram-active '/dev/zram' sh -c 'cat /proc/swaps'
expect_output etnaviv-active 'etnaviv' sh -c 'dmesg | grep -i etnaviv'

if [ "$release" -eq 1 ]; then
    if semanage permissive -l 2>/dev/null | grep -qx 'waydroid_t'; then
        record waydroid-enforcing FAIL 'waydroid_t is listed as permissive'
    else
        record waydroid-enforcing PASS 'waydroid_t is not listed as permissive'
    fi
    if tail -n +4 "$output_dir/avc-denials.txt" | grep -Eqi 'avc:.*denied'; then
        record unexplained-avc FAIL 'AVC denials require classification before release'
    else
        record unexplained-avc PASS 'no AVC denials found since boot'
    fi
else
    record waydroid-enforcing NOT_RUN 'development capture; repeat with --release on enforcing candidate'
    record unexplained-avc NOT_RUN 'development AVCs are evidence for policy refinement'
fi

if [ -n "$h264_file" ]; then
    if [ ! -r "$h264_file" ]; then
        record v4l2-h264-decode FAIL "unreadable input: $h264_file"
    elif command -v gst-launch-1.0 >/dev/null 2>&1; then
        decoder=v4l2h264dec
        gst-inspect-1.0 "$decoder" >/dev/null 2>&1 || decoder=v4l2slh264dec
        if timeout 120 gst-launch-1.0 -q filesrc location="$h264_file" ! \
            h264parse ! "$decoder" ! fakesink sync=false \
            >"$output_dir/v4l2-h264-decode.txt" 2>&1; then
            record v4l2-h264-decode PASS "$decoder completed"
        else
            record v4l2-h264-decode FAIL "see v4l2-h264-decode.txt"
        fi
    else
        record v4l2-h264-decode FAIL 'gst-launch-1.0 is unavailable'
    fi
else
    record v4l2-h264-decode NOT_RUN 'supply --h264 RAW_H264_FILE for an actual decode proof'
fi

printf 'Evidence: %s\n' "$output_dir"
printf 'Summary: %s\n' "$summary"
if grep -q "$(printf '\t')FAIL$(printf '\t')" "$summary"; then
    exit 1
fi

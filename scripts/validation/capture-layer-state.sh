#!/usr/bin/env bash
# Build one protected tuple and capture deterministic layer/package/task state.
set -euo pipefail

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 KAS_CONFIG MACHINE TARGET OUTPUT_DIR" >&2
    exit 2
fi

config=$1
machine=$2
target=$3
output_dir=$4

case "$output_dir" in
    /*) ;;
    *) output_dir="$PWD/$output_dir" ;;
esac
mkdir -p "$output_dir"

export KAS_MACHINE="$machine"
kas checkout "$config"

# Static layer surfaces are captured as well as BitBake's resolved view. This
# makes wildcard/dangling appends and global layer.conf policy visible even
# when they do not happen to alter the first recipe selected by BitBake.
find build/layers -type f -path '*/conf/layer.conf' -print0 \
    | sort -z \
    | xargs -0 grep -nHE \
        '(^|[[:space:]])(IMAGE_INSTALL|CORE_IMAGE_EXTRA_INSTALL|DISTRO_FEATURES|MACHINE_FEATURES|PACKAGECONFIG|PREFERRED_(VERSION|PROVIDER)|RDEPENDS)(:|[[:space:]])*([+?:.]?=)' \
        > "$output_dir/layer-conf-policy.txt" || true
find build/layers -type f -name '*.bbappend' -printf '%p\n' \
    | sed -E 's#^build/layers/[^/]+/#LAYER/#' \
    | sort -u > "$output_dir/all-bbappends.txt"

run_bitbake() {
    kas shell "$config" -c "$1"
}

run_bitbake "bitbake-layers show-layers" \
    | sed -E "s#$PWD/##g; s#[[:space:]]+$##" \
    > "$output_dir/layers.txt"
run_bitbake "bitbake-layers show-appends" \
    | sed -E "s#$PWD/##g; s#[[:space:]]+$##" \
    > "$output_dir/appends.txt"
run_bitbake "bitbake-layers show-recipes" \
    | sed -E "s#$PWD/##g; s#[[:space:]]+$##" \
    > "$output_dir/recipes.txt"

run_bitbake "bitbake -g $target"
sort -u build/pn-buildlist > "$output_dir/pn-buildlist.txt"
sed -E "s#$PWD/##g" build/task-depends.dot | sort -u \
    > "$output_dir/task-depends.dot"

# A parse-only graph is not proof that packaging, signing, recovery image size,
# or deploy layout still works. Complete the real image/recovery build for both
# baseline and candidate.
run_bitbake "bitbake $target"

deploy_dir="build/tmp/deploy/images/$machine"
if [ ! -d "$deploy_dir" ]; then
    echo "ERROR: deploy directory missing after successful build: $deploy_dir" >&2
    exit 1
fi

find "$deploy_dir" -maxdepth 1 -type f -printf '%f\t%s\n' \
    | sed -E 's/-[0-9]{14}(\.|-)/-TIMESTAMP\1/g' \
    | sort -u > "$output_dir/deploy-layout-and-sizes.txt"
# The expression belongs to awk; shell expansion would be a bug.
# shellcheck disable=SC2016
find "$deploy_dir" -maxdepth 1 -type f -name '*.manifest' -print0 \
    | sort -z \
    | xargs -0 -r awk '{print $1}' \
    | sort -u > "$output_dir/packages.txt"

# New warnings are regressions even when BitBake returns zero.
find build/tmp/log -type f -name 'console-latest.log' -print0 2>/dev/null \
    | xargs -0 -r grep -hE '(^|[[:space:]])WARNING:' \
    | sed -E "s#$PWD/##g; s/[0-9]{4}-[0-9]{2}-[0-9]{2}[^ ]*//g" \
    | sort -u > "$output_dir/warnings.txt" || true

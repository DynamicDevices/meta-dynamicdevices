#!/usr/bin/env bash
# Build one protected tuple and capture deterministic layer/package/task state.
set -euo pipefail

if [ "$#" -ne 6 ]; then
    echo "Usage: $0 KAS_CONFIG MACHINE DISTRO TARGET PRODUCT_FEATURES OUTPUT_DIR" >&2
    exit 2
fi

config=$1
machine=$2
distro=$3
target=$4
product_features=$5
output_dir=$6
test_keys_dir=${LAYER_ADOPTION_TEST_KEYS_DIR:-}
cache_root=${LAYER_ADOPTION_CACHE_DIR:-$HOME/yocto}

if [ -z "$test_keys_dir" ] || [ ! -d "$test_keys_dir" ]; then
    echo "ERROR: LAYER_ADOPTION_TEST_KEYS_DIR must name the generated test-key directory" >&2
    exit 2
fi
test_keys_dir=$(realpath "$test_keys_dir")
mkdir -p "$cache_root/downloads" "$cache_root/sstate-cache"
cache_root=$(realpath "$cache_root")
for key in \
    ubootdev.key ubootdev.crt spldev.key spldev.crt \
    privkey_modsign.pem x509_modsign.crt \
    uefi/DB.key uefi/DB.crt tf-a/privkey_ec_prime256v1.pem
do
    if [ ! -s "$test_keys_dir/$key" ]; then
        echo "ERROR: required test signing key is missing: $key" >&2
        exit 2
    fi
done

case "$output_dir" in
    /*) ;;
    *) output_dir="$PWD/$output_dir" ;;
esac
mkdir -p "$output_dir"

export KAS_MACHINE="$machine"
export KAS_DISTRO="$distro"
export DISTRO="$distro"

# KAS deliberately sanitises the environment before entering BitBake's build
# environment, so an exported DD_PRODUCT_FEATURES is silently lost. Inject the
# reviewed tuple value through a generated KAS overlay instead. JSON string
# quoting is also valid BitBake quoting and prevents tuple text from becoming
# local.conf syntax.
product_features_quoted=$(python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$product_features")
downloads_quoted=$(python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$cache_root/downloads")
sstate_quoted=$(python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$cache_root/sstate-cache")
repository_root=$(git rev-parse --show-toplevel)
overlay_dir="$repository_root/.layer-adoption-overlays"
mkdir -p "$overlay_dir"
overlay=$(mktemp "$overlay_dir/product-features.XXXXXX.yml")
cleanup_overlay() {
    rm -f "$overlay"
    rmdir "$overlay_dir" 2>/dev/null || true
}
trap cleanup_overlay EXIT
cat > "$overlay" <<EOF
header:
  version: 14
local_conf_header:
  layer-adoption-product-features: |
    DD_PRODUCT_FEATURES = $product_features_quoted
    DL_DIR = $downloads_quoted
    SSTATE_DIR = $sstate_quoted
    BB_DISKMON_DIRS = "STOPTASKS,\${TMPDIR},20G,100K STOPTASKS,\${DL_DIR},20G,100K STOPTASKS,\${SSTATE_DIR},20G,100K HALT,\${TMPDIR},10G,50K HALT,\${DL_DIR},10G,50K HALT,\${SSTATE_DIR},10G,50K"
    UBOOT_SIGN_KEYDIR:forcevariable = "$test_keys_dir"
    UBOOT_SPL_SIGN_KEYDIR:forcevariable = "$test_keys_dir"
    UEFI_SIGN_KEYDIR:forcevariable = "$test_keys_dir/uefi"
    MODSIGN_KEY_DIR:forcevariable = "$test_keys_dir"
    MODSIGN_PRIVKEY:forcevariable = "$test_keys_dir/privkey_modsign.pem"
    MODSIGN_X509:forcevariable = "$test_keys_dir/x509_modsign.crt"
    SIGNING_UBOOT_SIGN_KEY:forcevariable = "$test_keys_dir/ubootdev.key"
    SIGNING_UBOOT_SIGN_CRT:forcevariable = "$test_keys_dir/ubootdev.crt"
    SIGNING_UBOOT_SPL_SIGN_KEY:forcevariable = "$test_keys_dir/spldev.key"
    SIGNING_UBOOT_SPL_SIGN_CRT:forcevariable = "$test_keys_dir/spldev.crt"
    SIGNING_MODSIGN_PRIVKEY:forcevariable = "$test_keys_dir/privkey_modsign.pem"
    SIGNING_MODSIGN_X509:forcevariable = "$test_keys_dir/x509_modsign.crt"
    SIGNING_UEFI_SIGN_KEY:forcevariable = "$test_keys_dir/uefi/DB.key"
    SIGNING_UEFI_SIGN_CRT:forcevariable = "$test_keys_dir/uefi/DB.crt"
    OPTEE_TA_SIGN_KEY:forcevariable = "$test_keys_dir/ubootdev.key"
    TF_A_SIGN_KEY_PATH:forcevariable = "$test_keys_dir/tf-a/privkey_ec_prime256v1.pem"
EOF
combined_config="${config}:${overlay}"
kas checkout "$combined_config"

cat > "$output_dir/metadata.json" <<EOF
{"commit":"$(git rev-parse HEAD)","config":"$config","machine":"$machine","distro":"$distro","target":"$target","product_features":"$product_features"}
EOF

# Record only public fingerprints. This proves both halves of the comparison
# used the same signing identities without preserving disposable private keys.
for key in \
    ubootdev.key spldev.key privkey_modsign.pem uefi/DB.key \
    tf-a/privkey_ec_prime256v1.pem
do
    fingerprint=$(openssl pkey -in "$test_keys_dir/$key" -pubout -outform DER 2>/dev/null \
        | sha256sum | cut -d ' ' -f 1)
    printf '%s\t%s\n' "$key" "$fingerprint"
done > "$output_dir/test-signing-key-fingerprints.txt"
printf '%s\n' \
    "kas checkout CONFIG:PRODUCT_FEATURE_OVERLAY" \
    "bitbake-layers show-layers" \
    "bitbake-layers show-appends" \
    "bitbake-layers show-recipes" \
    "bitbake -g $target" \
    "bitbake -e $target" \
    "bitbake $target" \
    "DD_PRODUCT_FEATURES=$product_features" > "$output_dir/commands.txt"

# Static layer surfaces are captured as well as BitBake's resolved view. This
# makes wildcard/dangling appends and global layer.conf policy visible even
# when they do not happen to alter the first recipe selected by BitBake.
find build/layers "$repository_root" \
    -path "$repository_root/build" -prune -o \
    -path "$repository_root/.git" -prune -o \
    -type f \( -path '*/conf/layer.conf' -o -name '*.bbclass' \) -print0 \
    | sort -zu \
    | xargs -0 grep -nHE \
        '(^|[[:space:]])(IMAGE_INSTALL|CORE_IMAGE_|PACKAGE_INSTALL|DISTRO_FEATURES|MACHINE_FEATURES|PACKAGECONFIG|PREFERRED_(VERSION|PROVIDER)|DEFAULT_PREFERENCE|RDEPENDS|INHERIT|BBMASK|BBPATH|BBFILES|BBFILE_PRIORITY|INITRAMFS_MAXSIZE|IMAGE_FSTYPES|WKS_FILE|UBOOT_|KERNEL_|OPTEE_|SDKIMAGE_FEATURES|TOOLCHAIN_TARGET_TASK)(:|\[|[[:space:]])*([+?:.]?=)' \
    | sed -E "s#^$repository_root/#meta-dynamicdevices/#" \
    > "$output_dir/layer-conf-policy.txt" || true
find build/layers "$repository_root" \
    -path "$repository_root/build" -prune -o \
    -path "$repository_root/.git" -prune -o \
    -type f -name '*.bbappend' -printf '%p\n' \
    | sed -E -e 's#^build/layers/##' \
        -e "s#^$repository_root/#meta-dynamicdevices/#" \
    | sort -u > "$output_dir/all-bbappends.txt"

run_bitbake() {
    kas shell "$combined_config" -c "$1"
}

capture_command() {
    local name=$1
    shift
    local log="$output_dir/$name.log"
    if "$@" 2>&1 | tee "$log"; then
        return 0
    else
        local statuses=("${PIPESTATUS[@]}")
        echo "ERROR: command failed while capturing $name" >&2
        cat "$log" >&2
        return "${statuses[0]}"
    fi
}

normalise_kas_projection() {
    sed -E \
        -e '/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} - (DEBUG|INFO|WARNING|ERROR)[[:space:]]+- /d' \
        -e '/WARNING:/d' \
        -e '/^Summary: There were [0-9]+ WARNING messages?\.?$/d' \
        -e '/^NOTE: Starting bitbake server\.\.\.$/d' \
        -e 's#(/[^/[:space:]]+)*/(baseline|candidate)(/|$)#<REPO>\3#g' \
        -e 's/_(baseline|candidate)_build_layers_/_REPO_build_layers_/g' \
        -e "s#$PWD#<REPO>#g" \
        -e 's#[[:space:]]+$##'
}

capture_command show-layers run_bitbake "bitbake-layers show-layers" \
    | normalise_kas_projection \
    | python3 "$(dirname "$0")/canonicalise-bitbake-layer-output.py" layers \
    > "$output_dir/layers.txt"
capture_command show-appends run_bitbake "bitbake-layers show-appends" \
    | normalise_kas_projection \
    | python3 "$(dirname "$0")/canonicalise-bitbake-layer-output.py" appends \
    > "$output_dir/appends.txt"
capture_command show-recipes run_bitbake "bitbake-layers show-recipes" \
    | normalise_kas_projection \
    | python3 "$(dirname "$0")/canonicalise-bitbake-layer-output.py" recipes \
    > "$output_dir/recipes.txt"

capture_command graph run_bitbake "bitbake -g $target"
sort -u build/pn-buildlist > "$output_dir/pn-buildlist.txt"
sed -E "s#$PWD/##g" build/task-depends.dot | sort -u \
    > "$output_dir/task-depends.dot"
# Current BitBake deliberately removes the obsolete recipe-depends.dot output.
# pn-buildlist plus the finer-grained task graph retain provider and dependency
# selection coverage without relying on that removed compatibility artifact.

# Capture final values and BitBake's assignment provenance for policy that a
# newly enabled layer can silently change. The full environment is retained
# temporarily only as input, avoiding volatile host variables in comparisons.
# The complete environment is intentionally retained in evidence but is too
# large for routine CI output. capture_command still replays it to stderr if
# BitBake fails, so diagnostics are not lost.
capture_command environment run_bitbake "bitbake -e $target" >/dev/null
python3 "$(dirname "$0")/select-bitbake-env.py" \
    "$output_dir/environment.log" \
    | sed -E \
        -e 's#(/[^/[:space:]]+)*/(baseline|candidate)(/|$)#<REPO>\3#g' \
        -e 's/_(baseline|candidate)_build_layers_/_REPO_build_layers_/g' \
        -e "s#$PWD#<REPO>#g" \
        -e "s#$test_keys_dir#<TEST_KEYS>#g" \
        -e "s#$cache_root#<YOCTO_CACHE>#g" \
        -e 's/[0-9]{14}/TIMESTAMP/g' \
    > "$output_dir/selected-environment.txt"
require_selected_value() {
    local name=$1
    local expected=$2
    if ! grep -Fqx "$name=\"$expected\"" "$output_dir/selected-environment.txt"; then
        echo "ERROR: selected BitBake environment does not contain $name=\"$expected\"" >&2
        grep -E "^${name}=" "$output_dir/selected-environment.txt" >&2 || \
            echo "ERROR: $name is absent from selected BitBake environment" >&2
        return 1
    fi
}
require_selected_value MACHINE "$machine"
require_selected_value DISTRO "$distro"
require_selected_value DD_PRODUCT_FEATURES "$product_features"
require_selected_value MODSIGN_PRIVKEY "<TEST_KEYS>/privkey_modsign.pem"
require_selected_value MODSIGN_X509 "<TEST_KEYS>/x509_modsign.crt"
require_selected_value UBOOT_SIGN_KEYDIR "<TEST_KEYS>"
require_selected_value UBOOT_SPL_SIGN_KEYDIR "<TEST_KEYS>"
require_selected_value UEFI_SIGN_KEYDIR "<TEST_KEYS>/uefi"
require_selected_value OPTEE_TA_SIGN_KEY "<TEST_KEYS>/ubootdev.key"
require_selected_value TF_A_SIGN_KEY_PATH "<TEST_KEYS>/tf-a/privkey_ec_prime256v1.pem"
rm "$output_dir/environment.log"

# A parse-only graph is not proof that packaging, signing, recovery image size,
# or deploy layout still works. Complete the real image/recovery build for both
# baseline and candidate.
capture_command build run_bitbake "bitbake $target"

deploy_dir="build/tmp/deploy/images/$machine"
if [ ! -d "$deploy_dir" ]; then
    echo "ERROR: deploy directory missing after successful build: $deploy_dir" >&2
    exit 1
fi

find "$deploy_dir" -maxdepth 1 -type f -printf '%f\t%s\n' \
    | sed -E 's/-[0-9]{14}(\.|-|$)/-TIMESTAMP\1/g' \
    | sort -u > "$output_dir/deploy-layout-and-sizes.txt"
# The expression belongs to awk; shell expansion would be a bug.
# shellcheck disable=SC2016
find "$deploy_dir" -maxdepth 1 -type f -name '*.manifest' -print0 \
    | sort -z \
    | xargs -0 -r awk '{print $1}' \
    | sort -u > "$output_dir/packages.txt"

# New warnings are regressions even when BitBake returns zero.
# Cooker logs preserve one BitBake warning per line. Combined stdout/stderr
# command logs can splice concurrent parser warnings together and are not a
# deterministic warning source.
find build/tmp/log/cooker -type f -name '*.log' -print0 \
    | xargs -0 -r grep -hE '(^|[[:space:]])WARNING:' \
    | sed -E \
        -e 's/^.*WARNING:/WARNING:/' \
        -e 's#(/[^/[:space:]]+)*/(baseline|candidate)(/|$)#<REPO>\3#g' \
        -e "s#$PWD#<REPO>#g" \
        -e 's/[0-9]{4}-[0-9]{2}-[0-9]{2}[^ ]*//g' \
    | sort -u > "$output_dir/warnings.txt" || true

# Raw command logs are useful for diagnosis but contain progress ordering and
# timing noise. The deterministic projections and cooker warnings above are
# the comparison input.
rm -f "$output_dir"/*.log
# The generated overlay is removed by the EXIT trap. Keeping it inside the
# worktree satisfies KAS's same-repository rule for concatenated configs.

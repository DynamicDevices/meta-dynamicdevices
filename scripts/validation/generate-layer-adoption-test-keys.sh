#!/usr/bin/env bash
# Generate one genuine, test-only signing identity shared by compared builds.
set -euo pipefail
umask 077

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 OUTPUT_DIR" >&2
    exit 2
fi

output_dir=$(realpath -m "$1")
case "$output_dir" in
    /|/home|/root|/tmp|/var|/usr)
        echo "ERROR: refusing broad test-key output directory: $output_dir" >&2
        exit 2
        ;;
esac
if [ -e "$output_dir" ] && find "$output_dir" -mindepth 1 -print -quit | grep -q .; then
    echo "ERROR: test-key output directory is not empty: $output_dir" >&2
    exit 2
fi

mkdir -p "$output_dir/uefi" "$output_dir/tf-a"

make_rsa_certificate() {
    local key=$1
    local certificate=$2
    local common_name=$3
    openssl genpkey -algorithm RSA -out "$key" -pkeyopt rsa_keygen_bits:2048
    openssl req -batch -new -x509 -sha256 -days 2 \
        -key "$key" -out "$certificate" -subj "/CN=$common_name/"
    openssl pkey -in "$key" -check -noout
    openssl x509 -in "$certificate" -noout
}

make_rsa_certificate \
    "$output_dir/ubootdev.key" "$output_dir/ubootdev.crt" \
    layer-adoption-uboot
make_rsa_certificate \
    "$output_dir/spldev.key" "$output_dir/spldev.crt" \
    layer-adoption-spl
make_rsa_certificate \
    "$output_dir/privkey_modsign.pem" "$output_dir/x509_modsign.crt" \
    layer-adoption-module
make_rsa_certificate \
    "$output_dir/uefi/DB.key" "$output_dir/uefi/DB.crt" \
    layer-adoption-uefi

openssl ecparam -name prime256v1 -genkey -noout \
    -out "$output_dir/tf-a/privkey_ec_prime256v1.pem"
openssl ec -in "$output_dir/tf-a/privkey_ec_prime256v1.pem" -check -noout

printf 'PASS: generated test-only layer-adoption signing keys in %s\n' "$output_dir"

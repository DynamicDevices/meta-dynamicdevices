#!/usr/bin/env bash
# Generate or validate one genuine, test-only signing identity shared by builds.
set -euo pipefail
umask 077

if [ "$#" -ne 1 ] && { [ "$#" -ne 2 ] || [ "$1" != "--check" ]; }; then
    echo "Usage: $0 [--check] OUTPUT_DIR" >&2
    exit 2
fi

if [ "$#" -eq 2 ]; then
    check_only=true
    output_dir=$(realpath -m "$2")
else
    check_only=false
    output_dir=$(realpath -m "$1")
fi
case "$output_dir" in
    /|/home|/root|/tmp|/var|/usr)
        echo "ERROR: refusing broad test-key output directory: $output_dir" >&2
        exit 2
        ;;
esac
if [ "$check_only" = false ] && [ -e "$output_dir" ] && \
    find "$output_dir" -mindepth 1 -print -quit | grep -q .
then
    echo "ERROR: test-key output directory is not empty: $output_dir" >&2
    exit 2
fi

validate_pair() {
    local key=$1
    local certificate=$2
    local key_fingerprint certificate_fingerprint
    openssl pkey -in "$key" -check -noout >/dev/null 2>&1
    # Never let a persistent CI identity expire during a long gate run.
    openssl x509 -in "$certificate" -noout -checkend 604800 >/dev/null 2>&1
    key_fingerprint=$(openssl pkey -in "$key" -pubout -outform DER 2>/dev/null \
        | sha256sum | cut -d ' ' -f 1)
    certificate_fingerprint=$(openssl x509 -in "$certificate" -pubkey -noout 2>/dev/null \
        | openssl pkey -pubin -outform DER 2>/dev/null \
        | sha256sum | cut -d ' ' -f 1)
    [ "$key_fingerprint" = "$certificate_fingerprint" ]
}

validate_keyset() {
    validate_pair "$output_dir/ubootdev.key" "$output_dir/ubootdev.crt" &&
    validate_pair "$output_dir/spldev.key" "$output_dir/spldev.crt" &&
    validate_pair "$output_dir/privkey_modsign.pem" "$output_dir/x509_modsign.crt" &&
    validate_pair "$output_dir/uefi/DB.key" "$output_dir/uefi/DB.crt" &&
    openssl ec -in "$output_dir/tf-a/privkey_ec_prime256v1.pem" \
        -check -noout >/dev/null 2>&1
}

if [ "$check_only" = true ]; then
    if validate_keyset; then
        printf 'PASS: validated test-only layer-adoption signing keys in %s\n' "$output_dir"
        exit 0
    fi
    echo "ERROR: test-only layer-adoption signing keys are invalid or expire within seven days" >&2
    exit 1
fi

mkdir -p "$output_dir/uefi" "$output_dir/tf-a"

make_rsa_certificate() {
    local key=$1
    local certificate=$2
    local common_name=$3
    openssl genpkey -algorithm RSA -out "$key" -pkeyopt rsa_keygen_bits:2048
    openssl req -batch -new -x509 -sha256 -days 3650 \
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
validate_keyset

printf 'PASS: generated test-only layer-adoption signing keys in %s\n' "$output_dir"

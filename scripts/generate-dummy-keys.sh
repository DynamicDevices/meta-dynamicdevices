#!/bin/bash

# Generate dummy signing keys for local development builds
# These are NOT production keys and should never be used for real devices

set -e

KEYS_DIR="conf/factory-keys"

echo "Generating dummy signing keys for local development..."

# Create keys directory
mkdir -p "$KEYS_DIR"

# Generate OP-TEE signing key
if [ ! -f "$KEYS_DIR/opteedev.key" ]; then
    echo "Generating dummy OP-TEE signing key..."
    openssl genpkey -algorithm RSA -out "$KEYS_DIR/opteedev.key"
    openssl req -batch -new -x509 -key "$KEYS_DIR/opteedev.key" -out "$KEYS_DIR/opteedev.crt" -subj "/CN=DummyOpteeKey"
    echo "✅ Generated $KEYS_DIR/opteedev.key and $KEYS_DIR/opteedev.crt"
else
    echo "✅ OP-TEE signing key already exists"
fi

echo ""
echo "🔑 Dummy signing keys generated successfully!"
echo "⚠️  WARNING: These are dummy keys for local development only!"
echo "⚠️  NEVER use these keys for production devices!"
echo ""
echo "You can now run local mfgtools builds:"
echo "KAS_MACHINE=imx8mm-jaguar-sentai kas-container --runtime-args \"-v \${HOME}/yocto:/var/cache\" build kas/lmp-dynamicdevices-mfgtool.yml"

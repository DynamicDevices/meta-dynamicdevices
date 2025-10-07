#!/bin/bash

# Deployment script for security-compliance-cli
# Deploys to target device via SCP

set -e

TARGET_HOST="${1:-192.168.0.36}"
TARGET_USER="${2:-fio}"
TARGET_PATH="${3:-/usr/local/bin/}"

echo "🚀 Deploying security-compliance-cli to target..."
echo "   Host: $TARGET_USER@$TARGET_HOST"
echo "   Path: $TARGET_PATH"

# Check if ARM64 binary exists
if [ ! -f "target/aarch64-unknown-linux-gnu/release/security-compliance-cli" ]; then
    echo "❌ ARM64 binary not found. Run ./build-aarch64.sh first"
    exit 1
fi

# Deploy binary
echo "📦 Copying binary to target..."
scp target/aarch64-unknown-linux-gnu/release/security-compliance-cli $TARGET_USER@$TARGET_HOST:$TARGET_PATH

# Make executable
echo "🔧 Setting executable permissions..."
ssh $TARGET_USER@$TARGET_HOST "chmod +x ${TARGET_PATH}security-compliance-cli"

# Test deployment
echo "🧪 Testing deployment..."
ssh $TARGET_USER@$TARGET_HOST "${TARGET_PATH}security-compliance-cli --version" || {
    echo "❌ Deployment test failed"
    exit 1
}

echo "✅ Deployment successful!"
echo "🎯 Run tests with: ssh $TARGET_USER@$TARGET_HOST '${TARGET_PATH}security-compliance-cli test'"

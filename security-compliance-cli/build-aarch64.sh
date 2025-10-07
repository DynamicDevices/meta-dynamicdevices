#!/bin/bash

# Cross-compilation script for ARM64 (AArch64)
# Based on eink-power-cli build structure

set -e

echo "🔧 Building security-compliance-cli for ARM64..."

# Check if cross-compilation target is installed
if ! rustup target list --installed | grep -q "aarch64-unknown-linux-gnu"; then
    echo "📦 Installing ARM64 target..."
    rustup target add aarch64-unknown-linux-gnu
fi

# Build for ARM64
echo "🏗️  Building for aarch64-unknown-linux-gnu..."
cargo build --release --target aarch64-unknown-linux-gnu

# Check if build was successful
if [ -f "target/aarch64-unknown-linux-gnu/release/security-compliance-cli" ]; then
    echo "✅ Build successful!"
    echo "📁 Binary location: target/aarch64-unknown-linux-gnu/release/security-compliance-cli"
    
    # Show binary info
    file target/aarch64-unknown-linux-gnu/release/security-compliance-cli
    ls -lh target/aarch64-unknown-linux-gnu/release/security-compliance-cli
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🎉 ARM64 build completed successfully!"

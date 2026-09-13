#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
BUILD_TOOLS="${BUILD_TOOLS:-$(find "$SDK_ROOT/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)}"
PLATFORM="${ANDROID_PLATFORM:-$(find "$SDK_ROOT/platforms" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)}"
ANDROID_JAR="$PLATFORM/android.jar"
OUT="$SCRIPT_DIR/out"

mkdir -p "$OUT"
find "$OUT" -mindepth 1 -delete
mkdir -p "$OUT/classes" "$OUT/dex"

javac -source 8 -target 8 -Xlint:-options \
    -bootclasspath "$ANDROID_JAR" \
    -d "$OUT/classes" \
    app/src/main/java/com/dynamicdevices/jaguargpu/MainActivity.java

jar --create --file "$OUT/classes.jar" -C "$OUT/classes" .
"$BUILD_TOOLS/d8" \
    --lib "$ANDROID_JAR" \
    --min-api 29 \
    --output "$OUT/dex" \
    "$OUT/classes.jar"

"$BUILD_TOOLS/aapt2" link \
    -I "$ANDROID_JAR" \
    --manifest app/src/main/AndroidManifest.xml \
    --min-sdk-version 29 \
    --target-sdk-version 35 \
    -o "$OUT/jaguar-gpu-demo-unsigned.apk"

cd "$OUT/dex"
zip -q -u "$OUT/jaguar-gpu-demo-unsigned.apk" classes.dex
cd - >/dev/null

KEYSTORE="$HOME/.android/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
    mkdir -p "$(dirname "$KEYSTORE")"
    keytool -genkeypair -keystore "$KEYSTORE" -storepass android -keypass android \
        -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
fi

"$BUILD_TOOLS/zipalign" -f 4 \
    "$OUT/jaguar-gpu-demo-unsigned.apk" "$OUT/jaguar-gpu-demo-aligned.apk"
"$BUILD_TOOLS/apksigner" sign \
    --ks "$KEYSTORE" --ks-pass pass:android --key-pass pass:android \
    --out "$OUT/jaguar-gpu-demo.apk" "$OUT/jaguar-gpu-demo-aligned.apk"
"$BUILD_TOOLS/apksigner" verify --verbose "$OUT/jaguar-gpu-demo.apk"
printf 'Built %s\n' "$OUT/jaguar-gpu-demo.apk"

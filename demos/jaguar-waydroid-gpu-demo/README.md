# Jaguar Waydroid GPU demo

An offline OpenGL ES 2.0 starfield benchmark for the Jaguar Screen Waydroid
image. It displays the renderer reported by Android, live FPS, and particle
count. Tap the screen to cycle through 2,000, 10,000, 40,000, and 80,000
particles.

## Build

```sh
./build.sh
```

The build uses the latest Android SDK platform and build-tools installed under
`ANDROID_SDK_ROOT` or `~/Android/Sdk`. It compiles directly with the SDK
tools, so Gradle and network access are not required. The result is
`out/jaguar-gpu-demo.apk`, signed with the standard local Android debug key.

## Install on Jaguar Screen

Run the Waydroid commands as the same `weston` user that owns the graphical
session:

```sh
sudo -u weston env \
  HOME=/var/rootdirs/home/weston \
  XDG_RUNTIME_DIR=/run/user/63 \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/63/bus \
  WAYLAND_DISPLAY=wayland-1 \
  waydroid app install /tmp/jaguar-gpu-demo.apk

sudo -u weston env \
  HOME=/var/rootdirs/home/weston \
  XDG_RUNTIME_DIR=/run/user/63 \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/63/bus \
  WAYLAND_DISPLAY=wayland-1 \
  waydroid app launch com.dynamicdevices.jaguargpu
```

The v1.0.0 bench baseline rendered 10,000 particles at approximately 13 fps at
the panel's full 1920x1200 logical resolution. The overlay identified
`Vivante GC600 rev 4653` and `OpenGL ES 2.0`.

The APK uses only Android platform APIs and has no network permission or
external runtime dependency.

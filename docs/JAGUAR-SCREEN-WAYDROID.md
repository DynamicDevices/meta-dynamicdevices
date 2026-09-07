# Jaguar Screen Waydroid

## Released baseline

Jaguar Screen Waydroid v1.0.0 boots the physical
`imx8mm-jaguar-screen` board from a Foundries-built LmP image into a
full-screen LineageOS desktop. The first proven image was Foundries target
2887, built from manifest `88ab13ce2c5f611847566be3d1b8f9f4b4ca47cf`.

The validated display path is:

```text
LineageOS SurfaceFlinger
    -> Waydroid minigbm / Mesa
    -> etnaviv render node
    -> Weston on card2
    -> DRM DSI-1
    -> ST1010B3CYOL / HX8279-D panel at 1920x1200 logical
```

SurfaceFlinger reported `Mesa, Vivante GC600 rev 4653, OpenGL ES 2.0 Mesa
26.0.1`. Weston used `renderD128` and the same GC600 renderer. This proves
hardware rendering on both sides of the Waydroid/Wayland boundary.

## Boot contract

The machine enables these services:

1. `waydroid-image-provision.service` checks persistent
   `/var/lib/waydroid/images` and runs `waydroid init` only when either
   image is missing.
2. `waydroid-jaguar-container.service` owns the long-running container.
3. `waydroid-jaguar-session.service` runs as the fixed `weston` user and
   binds the Android session to Weston.
4. `waydroid-jaguar-ui.service` waits for the session and opens the
   full-screen Android UI.

Weston is pinned to DRM `card2`; `card0` is the firmware framebuffer and
`card1` is the render-only etnaviv node. The physical panel scans out at
1200x1920 and Weston applies `transform=rotate-90` to expose a 1920x1200
landscape desktop. Its handover background must therefore use
`active-edge-splash-1920x1200.png`.

Android images are deliberately stored outside OSTree in
`/var/lib/waydroid/images`. A Foundries OS update changes the host and
services without replacing an already-provisioned Android image. Delete or
replace those images only as a deliberate image-management operation.

## Host requirements

The release requires:

- Binder and Android host kernel support;
- pressure stall information for Android `lmkd`;
- etnaviv DRM and the Vivante GC600 device-tree nodes;
- Wayland, OpenGL and the Waydroid distro feature;
- persistent storage for the Android system and vendor images.

The Screen machine accepts etnaviv/OpenGL without requiring Vulkan because the
GC600 exposes OpenGL ES 2.0.

## Operations

Check the complete stack:

```sh
systemctl is-active \
  weston.service \
  waydroid-jaguar-container.service \
  waydroid-jaguar-session.service \
  waydroid-jaguar-ui.service
waydroid status
```

Run `waydroid app install` and `waydroid app launch` as the `weston`
session user. The exact environment is shown in
`demos/jaguar-waydroid-gpu-demo/README.md`.

The boot firmware must leave WDOG1 disabled. Both
`CONFIG_SPL_WATCHDOG` and `CONFIG_WATCHDOG_AUTOSTART` are disabled in the
Screen U-Boot configuration so Linux can perform an immediate reset.

## Demonstration

`demos/jaguar-waydroid-gpu-demo` is the release demonstration and a bounded
graphics load. It is an offline GLES 2 star tunnel with live FPS, renderer
identity and tap-selectable particle counts. It avoids browser GPU policy and
network availability, making it suitable for repeatable bench and visitor
demos.

The first physical run at 10,000 particles reported approximately 13 fps and
identified `Vivante GC600 rev 4653`. Use the lower setting for a smooth
visual introduction and increase the particle count to demonstrate scaling.

# Jaguar Screen Waydroid v1.0.0

Release date: 2026-09-07

This release establishes the first reproducible Foundries-built Jaguar Screen
image that boots directly into a GPU-accelerated LineageOS/Waydroid desktop on
the physical 1920x1200 display.

## Included

- seamless U-Boot to Linux display handover;
- upright Active Edge splash through the Weston handover;
- automatic persistent Android image provisioning;
- automatic Waydroid container, session and full-screen UI startup;
- Binder, pressure stall and etnaviv host support;
- Mesa GC600 acceleration in Weston and Android SurfaceFlinger;
- a two-second final reboot watchdog, applied after unmount and sync;
- offline Jaguar GPU Drive demo with live FPS and adjustable particle load.

## Evidence

- Board: `imx8mm-jaguar-screen-2210a09dab86563`
- First proven Foundries image: target 2887
- Resolution: 1920x1200 logical, 1200x1920 native panel scanout
- Android renderer: `Vivante GC600 rev 4653`
- API: `OpenGL ES 2.0 Mesa 26.0.1`
- Demo baseline: approximately 13 fps at 10,000 particles

Target 2888 was rejected after physical validation: disabling the SPL watchdog
did not remove the reboot delay and affected the proven boot presentation. A
later release candidate must restore the target 2887 boot display path and
prove the two-second final reboot watchdog on the board. A live configuration
test reduced the measured gap from `systemd-shutdown: Rebooting` to SPL from
59.5 seconds to 2.48 seconds. The release tags will identify the exact manifest
and layer commits used by the final Foundries target.

## Known limits

- Android images are provisioned separately into persistent storage; they are
  not yet fetched from a product-controlled image channel.
- The GC600 exposes GLES 2.0. Chromium WebView 146 requests GLES 3 and
  blocklists WebGL without development flags, so the release demo uses a
  native GLES 2 application.
- Touch mapping and the visual design of the benchmark have further refinement
  opportunities after this baseline.

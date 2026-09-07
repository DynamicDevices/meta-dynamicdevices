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
- immediate reboot support by keeping WDOG1 disabled through SPL and U-Boot;
- offline Jaguar GPU Drive demo with live FPS and adjustable particle load.

## Evidence

- Board: `imx8mm-jaguar-screen-2210a09dab86563`
- First proven Foundries image: target 2887
- Resolution: 1920x1200 logical, 1200x1920 native panel scanout
- Android renderer: `Vivante GC600 rev 4653`
- API: `OpenGL ES 2.0 Mesa 26.0.1`
- Demo baseline: approximately 13 fps at 10,000 particles

Target 2888 validates the final splash-orientation and SPL watchdog fixes. The
release manifest adds this documentation and the demo source; it does not
change the installed image. The release tags identify the exact manifest and
layer commits used by the final release target.

## Known limits

- Android images are provisioned separately into persistent storage; they are
  not yet fetched from a product-controlled image channel.
- The GC600 exposes GLES 2.0. Chromium WebView 146 requests GLES 3 and
  blocklists WebGL without development flags, so the release demo uses a
  native GLES 2 application.
- Touch mapping and the visual design of the benchmark have further refinement
  opportunities after this baseline.

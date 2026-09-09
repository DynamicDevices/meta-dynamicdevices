# Waydroid memory profile for i.MX8MM 2 GB

The `imx8mm-jaguar-screen` Waydroid image enables a 768 MiB LZ4 zram swap
device before the container starts. The container has a provisional
`MemoryHigh` of 1200 MiB and `MemoryMax` of 1500 MiB.

These values are starting controls, not proof of capacity. On the shipping
image, run:

```sh
/usr/libexec/waydroid-memory-headroom
```

Collect results at idle, after kiosk launch, during video playback, during an
application update and after repeated application restarts. The report takes a
two-second CPU sample and records the host filesystems that contain Waydroid's
state and images. Also check the kernel journal for OOM kills and zram
writeback failures.

`waydroid-board-evidence capture` also records raw SurfaceFlinger presentation
timestamps and summarizes the target refresh rate, effective frame rate,
missed refresh intervals and worst frame gap. Capture this during steady-state
shipping kiosk animation and video playback; an idle surface is not a valid
frame-rate headroom measurement.

Resource gates under the target workload:

- green: container peak below 70% of `MemoryMax` and host available memory
  above 30%, CPU busy below 70% with idle above 30%, and relevant filesystems
  below 70%;
- amber: RAM or filesystem use reaches 70%, CPU busy reaches 70%, or CPU idle
  falls to 30%;
- red: RAM or filesystem use reaches 85%, CPU busy reaches 85%, CPU idle falls
  to 15%, `memory.events` reports `oom`/`oom_kill`, or the kernel OOM killer
  runs.

Adjust `MemoryHigh`, `MemoryMax` or zram size only from recorded board data.

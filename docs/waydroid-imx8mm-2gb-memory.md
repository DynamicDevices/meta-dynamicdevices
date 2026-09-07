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
application update and after repeated application restarts. Also check the
kernel journal for OOM kills and zram writeback failures.

Resource gates under the target workload:

- green: container peak below 70% of `MemoryMax` and host available memory
  above 30%;
- amber: either reaches 70%;
- red: either reaches 85%, `memory.events` reports `oom`/`oom_kill`, or the
  kernel OOM killer runs.

Adjust `MemoryHigh`, `MemoryMax` or zram size only from recorded board data.

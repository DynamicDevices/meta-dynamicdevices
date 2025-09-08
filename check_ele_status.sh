#!/bin/bash
# EdgeLock Enclave Status Check Script for imx93-jaguar-eink
# Run this script directly on the board to verify ELE functionality

echo "=== System Information ==="
uname -a
echo ""

echo "=== EdgeLock Enclave Kernel Messages ==="
dmesg | grep -i "ele\|enclave\|s4muap" | head -20
echo ""

echo "=== ELE Device Status ==="
ls -la /dev/*ele* 2>/dev/null || echo "No ELE devices found in /dev"
echo ""

echo "=== S4MUAP Device Tree Status ==="
find /proc/device-tree -name "*s4muap*" -o -name "*ele*" 2>/dev/null | head -10
echo ""

echo "=== ELE Driver Status ==="
lsmod | grep -i ele || echo "No ELE modules loaded"
echo ""

echo "=== Secure Boot Status ==="
cat /proc/cmdline | grep -o "sec_boot=[^ ]*" || echo "sec_boot not found in cmdline"
echo ""

echo "=== OCOTP/NVMEM Status (ELE-based) ==="
ls -la /sys/bus/nvmem/devices/ 2>/dev/null | grep -i "ocotp\|ele" || echo "No OCOTP/ELE NVMEM devices found"
echo ""

echo "=== ELE Hardware Random Number Generator ==="
ls -la /dev/hwrng 2>/dev/null && cat /sys/class/misc/hw_random/rng_current 2>/dev/null || echo "No hardware RNG found"
echo ""

echo "=== ELE Crypto Status ==="
cat /proc/crypto | grep -A 5 -B 5 "imx-ele" 2>/dev/null || echo "No ELE crypto drivers found"
echo ""

echo "=== Recent Boot Messages ==="
journalctl -b | grep -i "ele\|enclave\|secure" | tail -10 || echo "No recent ELE messages in journal"

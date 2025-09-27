#!/usr/bin/env python3
"""
Boot Logger - Captures all serial data with intelligent timeout
- Logs from /dev/ttyUSB1 at 115200 baud
- Times out after 10s of no data
- Once data starts flowing, continues until manually stopped
- Logs everything to file and displays progress
"""

import serial
import sys
import time
from datetime import datetime

def main():
    device = "/dev/ttyUSB1"
    baud = 115200
    timeout_seconds = 10
    log_filename = f"boot_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    
    print("=" * 60)
    print("BOOT LOGGER - Complete Serial Capture")
    print("=" * 60)
    print(f"Device: {device}")
    print(f"Baud Rate: {baud}")
    print(f"Timeout: {timeout_seconds}s (only if no data received)")
    print(f"Log File: {log_filename}")
    print()
    print("🔌 Connecting to serial port...")
    
    try:
        # Open serial connection
        ser = serial.Serial(device, baud, timeout=1)
        print(f"✅ Connected to {ser.name}")
        print(f"📝 Logging to: {log_filename}")
        print()
    print("⏱️  Waiting for boot log data (10s timeout if no activity)...")
    print("📡 Once boot data starts flowing, will continue until Ctrl+C")
    print("🔄 Power cycle the board now to capture complete boot sequence!")
    print("📋 Will capture: U-Boot SPL → U-Boot → Kernel → Init → Services")
    print("-" * 60)
        
        data_received = False
        last_data_time = time.time()
        total_bytes = 0
        
        with open(log_filename, 'w') as log_file:
            log_file.write(f"=== Boot Log Started ===\n")
            log_file.write(f"Device: {device}\n")
            log_file.write(f"Baud: {baud}\n")
            log_file.write(f"Time: {datetime.now()}\n")
            log_file.write(f"========================================\n")
            log_file.flush()
            
            while True:
                current_time = time.time()
                
                # Check for timeout only if no data has been received yet
                if not data_received and (current_time - last_data_time) > timeout_seconds:
                    print(f"\n⏰ Timeout: No data received for {timeout_seconds} seconds")
                    break
                
                if ser.in_waiting > 0:
                    data = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                    if data:
                        if not data_received:
                            print("🎯 Data detected! Logging started...")
                            data_received = True
                        
                        # Update counters
                        total_bytes += len(data)
                        last_data_time = current_time
                        
                        # Display and log data
                        sys.stdout.write(data)
                        sys.stdout.flush()
                        log_file.write(data)
                        log_file.flush()
                        
                        # Show progress every 1KB
                        if total_bytes % 1024 == 0 and total_bytes > 0:
                            print(f"\r📊 Logged: {total_bytes} bytes", end="", flush=True)
                
                time.sleep(0.05)  # Small delay to prevent busy-waiting
        
        print(f"\n📈 Total bytes logged: {total_bytes}")
        
    except serial.SerialException as e:
        print(f"❌ Serial error: {e}")
        print("💡 Make sure /dev/ttyUSB1 exists and is accessible")
    except KeyboardInterrupt:
        print(f"\n⏹️  Logging stopped by user")
        print(f"📈 Total bytes logged: {total_bytes}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("🔌 Serial connection closed")
        print(f"📝 Complete log saved to: {log_filename}")

if __name__ == "__main__":
    main()

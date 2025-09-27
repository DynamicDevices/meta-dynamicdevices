#!/usr/bin/env python3
"""
Simple Serial Monitor for Board Boot Logs
Stays open and waits for data - perfect for capturing boot sequences
"""

import serial
import sys
import time
from datetime import datetime

def main():
    device = "/dev/ttyUSB1"
    baud = 115200
    log_filename = f"boot_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    
    print("=" * 60)
    print("SIMPLE SERIAL MONITOR FOR BOOT LOGS")
    print("=" * 60)
    print(f"Device: {device}")
    print(f"Baud Rate: {baud}")
    print(f"Log File: {log_filename}")
    print()
    print("🔌 READY - Please power cycle the board now!")
    print("📝 All output will be logged and displayed")
    print("⏹️  Press Ctrl+C to stop monitoring")
    print("-" * 60)
    
    try:
        # Open serial connection
        ser = serial.Serial(device, baud, timeout=1)
        print(f"✅ Connected to {device}")
        
        # Open log file
        with open(log_filename, 'w') as log_file:
            log_file.write(f"=== Boot Log Started ===\n")
            log_file.write(f"Device: {device}\n")
            log_file.write(f"Baud: {baud}\n")
            log_file.write(f"Time: {datetime.now()}\n")
            log_file.write("=" * 40 + "\n")
            log_file.flush()
            
            print(f"📝 Logging to: {log_filename}")
            print("🔄 Waiting for boot data...")
            print()
            
            # Main monitoring loop
            while True:
                try:
                    # Read data if available
                    if ser.in_waiting > 0:
                        data = ser.read(ser.in_waiting)
                        text = data.decode('utf-8', errors='replace')
                        
                        # Display with timestamp
                        timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]
                        for line in text.splitlines():
                            if line.strip():
                                output = f"[{timestamp}] {line}"
                                print(output)
                                log_file.write(output + "\n")
                                log_file.flush()
                    
                    # Small delay to prevent CPU spinning
                    time.sleep(0.01)
                    
                except UnicodeDecodeError:
                    # Handle binary data gracefully
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] <binary data>")
                    continue
                    
    except KeyboardInterrupt:
        print("\n🛑 Monitoring stopped by user")
        
    except serial.SerialException as e:
        print(f"❌ Serial error: {e}")
        sys.exit(1)
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)
        
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("🔌 Serial connection closed")
        print(f"📝 Log saved to: {log_filename}")

if __name__ == "__main__":
    main()

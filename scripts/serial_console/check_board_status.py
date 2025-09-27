#!/usr/bin/env python3
"""
i.MX93 Jaguar E-Ink Board Status Checker
Quick check to see if the board is responsive via local serial console

Usage: python3 check_board_status.py [options]
"""

import sys
import time
import serial
import argparse
from datetime import datetime
from typing import Optional

# Default Configuration
DEFAULT_SERIAL_DEVICE = "/dev/ttyUSB1"
DEFAULT_BAUD_RATE = 115200

# Colors for output
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    NC = '\033[0m'

def print_status(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.GREEN}[{timestamp}] [INFO]{Colors.NC} {msg}", flush=True)

def print_warning(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.YELLOW}[{timestamp}] [WARN]{Colors.NC} {msg}", flush=True)

def print_error(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.RED}[{timestamp}] [ERROR]{Colors.NC} {msg}", flush=True)

def print_success(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.CYAN}[{timestamp}] [SUCCESS]{Colors.NC} {msg}", flush=True)

class BoardStatusChecker:
    def __init__(self, device: str = DEFAULT_SERIAL_DEVICE, baud: int = DEFAULT_BAUD_RATE):
        self.device = device
        self.baud = baud
        self.serial_conn = None
    
    def connect(self) -> bool:
        """Connect to serial port"""
        try:
            print_status(f"Connecting to {self.device} at {self.baud} baud...")
            self.serial_conn = serial.Serial(
                port=self.device,
                baudrate=self.baud,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=1,
                xonxoff=False,
                rtscts=False,
                dsrdtr=False
            )
            
            # Clear any pending data
            self.serial_conn.flushInput()
            self.serial_conn.flushOutput()
            
            print_success(f"Connected to {self.device}")
            return True
            
        except Exception as e:
            print_error(f"Failed to connect to {self.device}: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from serial port"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            print_status("Serial connection closed")
    
    def send_command(self, command: str) -> bool:
        """Send command to serial port"""
        if not self.serial_conn or not self.serial_conn.is_open:
            print_error("Serial connection not open")
            return False
        
        try:
            # Send Ctrl+C first to interrupt any running commands
            self.serial_conn.write(b'\x03')
            time.sleep(0.1)
            
            # Send the actual command
            cmd_bytes = (command + '\n').encode('utf-8')
            self.serial_conn.write(cmd_bytes)
            self.serial_conn.flush()
            print_status(f"Sent command: {command}")
            return True
        except Exception as e:
            print_error(f"Failed to send command '{command}': {e}")
            return False
    
    def read_response(self, timeout: float = 5.0) -> str:
        """Read response from serial port"""
        if not self.serial_conn or not self.serial_conn.is_open:
            return ""
        
        response_lines = []
        start_time = time.time()
        
        try:
            while (time.time() - start_time) < timeout:
                if self.serial_conn.in_waiting > 0:
                    line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                    if line:
                        response_lines.append(line)
                        print(f"  {line}")
                else:
                    time.sleep(0.1)
            
            return '\n'.join(response_lines)
            
        except Exception as e:
            print_error(f"Error reading response: {e}")
            return ""
    
    def test_basic_communication(self) -> bool:
        """Test basic communication with the board"""
        print_status("Testing basic communication...")
        
        # Clear any pending output first
        print_status("Clearing serial buffer...")
        try:
            self.serial_conn.flushInput()
            self.serial_conn.flushOutput()
            
            # Send some newlines and Ctrl+C to clear any pending commands
            self.serial_conn.write(b'\x03\n\n\n')
            time.sleep(1)
            
            # Clear any response
            while self.serial_conn.in_waiting > 0:
                self.serial_conn.read(self.serial_conn.in_waiting)
                time.sleep(0.1)
            
        except Exception as e:
            print_warning(f"Buffer clearing failed: {e}")
        
        # Test different commands to see what responds
        test_commands = [
            ("", "Empty command (check for prompt)"),
            ("help", "Help command"),
            ("uname -a", "Linux uname command"),
            ("cat /proc/version", "Kernel version"),
            ("whoami", "Current user"),
            ("ls /", "Root directory listing"),
            ("dmesg | tail -5", "Recent kernel messages")
        ]
        
        responses_received = 0
        
        for cmd, description in test_commands:
            print_status(f"Testing: {description}")
            
            if self.send_command(cmd):
                response = self.read_response(timeout=3.0)
                
                if response:
                    responses_received += 1
                    
                    # Analyze response
                    if "login:" in response.lower():
                        print_success("✅ Login prompt detected - board is at login screen")
                        return True
                    elif any(prompt in response for prompt in ["$", "#", "root@", "fio@"]):
                        print_success("✅ Shell prompt detected - board is logged in")
                        return True
                    elif "command not found" in response.lower():
                        print_success("✅ Shell is responding (command not found)")
                        return True
                    elif "Linux" in response and "version" in response:
                        print_success("✅ Linux system responding")
                        return True
                    elif len(response) > 10:
                        print_success("✅ Board is responding with data")
                        return True
                else:
                    print_warning(f"No response to: {cmd}")
            
            time.sleep(0.5)
        
        if responses_received > 0:
            print_warning(f"⚠️ Board responding but not in expected state ({responses_received} responses)")
            return True
        else:
            print_error("❌ No responses received from board")
            return False
    
    def monitor_output(self, duration: int = 10) -> bool:
        """Monitor serial output for activity"""
        print_status(f"Monitoring serial output for {duration} seconds...")
        
        start_time = time.time()
        lines_received = 0
        
        try:
            while (time.time() - start_time) < duration:
                if self.serial_conn.in_waiting > 0:
                    line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                    if line:
                        lines_received += 1
                        timestamp = datetime.now().strftime('%H:%M:%S')
                        print(f"[{timestamp}] {line}")
                        
                        # Check for specific patterns
                        if "login:" in line.lower():
                            print_success("Login prompt detected!")
                        elif any(prompt in line for prompt in ["$", "#", "fio@"]):
                            print_success("Shell prompt detected!")
                        elif "kernel" in line.lower() and ("panic" in line.lower() or "oops" in line.lower()):
                            print_error("Kernel error detected!")
                        elif "rcu" in line.lower() and "stall" in line.lower():
                            print_error("RCU stall detected!")
                else:
                    time.sleep(0.1)
        
        except KeyboardInterrupt:
            print_warning("Monitoring interrupted by user")
        
        elapsed = time.time() - start_time
        
        if lines_received > 0:
            print_success(f"✅ Received {lines_received} lines in {elapsed:.1f} seconds")
            return True
        else:
            print_warning(f"⚠️ No output received in {elapsed:.1f} seconds")
            return False
    
    def check_board_state(self) -> str:
        """Determine the current state of the board"""
        print_status("Determining board state...")
        
        # First, just listen for a few seconds to see if there's any activity
        print_status("Listening for spontaneous output...")
        
        activity_detected = False
        boot_activity = False
        
        start_time = time.time()
        while (time.time() - start_time) < 5:
            if self.serial_conn.in_waiting > 0:
                line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    activity_detected = True
                    print(f"  {line}")
                    
                    # Check for boot-related activity
                    if any(pattern in line.lower() for pattern in 
                          ['u-boot', 'linux', 'kernel', 'systemd', 'starting', 'booting']):
                        boot_activity = True
            else:
                time.sleep(0.1)
        
        if boot_activity:
            return "BOOTING"
        elif activity_detected:
            return "ACTIVE"
        
        # No spontaneous activity, try to interact
        communication_works = self.test_basic_communication()
        
        if communication_works:
            return "RESPONSIVE"
        else:
            return "UNRESPONSIVE"
    
    def run_full_check(self) -> dict:
        """Run complete board status check"""
        print("=" * 60)
        print("i.MX93 JAGUAR E-INK BOARD STATUS CHECK")
        print("=" * 60)
        
        results = {
            'connected': False,
            'state': 'UNKNOWN',
            'responsive': False,
            'activity_detected': False,
            'recommendations': []
        }
        
        # Test serial connection
        if not self.connect():
            results['recommendations'].append("Check serial cable connection")
            results['recommendations'].append("Verify correct serial device path")
            results['recommendations'].append("Check board power supply")
            return results
        
        results['connected'] = True
        
        try:
            # Determine board state
            state = self.check_board_state()
            results['state'] = state
            
            if state == "BOOTING":
                print_success("✅ Board is currently booting")
                results['activity_detected'] = True
                results['recommendations'].append("Wait for boot to complete")
                results['recommendations'].append("Monitor boot process with test_boot_process.py")
                
            elif state == "RESPONSIVE":
                print_success("✅ Board is responsive and ready")
                results['responsive'] = True
                results['recommendations'].append("Board is ready for testing")
                results['recommendations'].append("You can run commands or tests")
                
            elif state == "ACTIVE":
                print_warning("⚠️ Board is active but not responding to commands")
                results['activity_detected'] = True
                results['recommendations'].append("Board may be running but not at shell prompt")
                results['recommendations'].append("Try pressing Enter or Ctrl+C")
                results['recommendations'].append("May need to login first")
                
            else:  # UNRESPONSIVE
                print_error("❌ Board is not responding")
                results['recommendations'].append("Check if board is powered on")
                results['recommendations'].append("Verify board is in boot mode (not programming mode)")
                results['recommendations'].append("Try resetting the board")
                results['recommendations'].append("Check boot pin configuration")
            
            # Additional monitoring if not clearly responsive
            if state != "RESPONSIVE":
                print_status("Running extended monitoring...")
                activity = self.monitor_output(duration=10)
                if activity:
                    results['activity_detected'] = True
        
        finally:
            self.disconnect()
        
        # Print summary
        print("\n" + "=" * 60)
        print("BOARD STATUS SUMMARY")
        print("=" * 60)
        print(f"Connection: {'✅ SUCCESS' if results['connected'] else '❌ FAILED'}")
        print(f"Board State: {results['state']}")
        print(f"Responsive: {'✅ YES' if results['responsive'] else '❌ NO'}")
        print(f"Activity: {'✅ DETECTED' if results['activity_detected'] else '❌ NONE'}")
        
        if results['recommendations']:
            print("\nRecommendations:")
            for i, rec in enumerate(results['recommendations'], 1):
                print(f"  {i}. {rec}")
        
        print("=" * 60)
        
        return results

def main():
    parser = argparse.ArgumentParser(description="i.MX93 Jaguar E-Ink Board Status Checker")
    parser.add_argument("-d", "--device", default=DEFAULT_SERIAL_DEVICE,
                       help=f"Serial device (default: {DEFAULT_SERIAL_DEVICE})")
    parser.add_argument("-b", "--baud", type=int, default=DEFAULT_BAUD_RATE,
                       help=f"Baud rate (default: {DEFAULT_BAUD_RATE})")
    parser.add_argument("--monitor", type=int, metavar="SECONDS",
                       help="Just monitor output for specified seconds")
    parser.add_argument("--test-comm", action="store_true",
                       help="Just test basic communication")
    
    args = parser.parse_args()
    
    checker = BoardStatusChecker(device=args.device, baud=args.baud)
    
    if args.monitor:
        # Monitor mode
        if checker.connect():
            try:
                checker.monitor_output(duration=args.monitor)
            except KeyboardInterrupt:
                print_status("Monitoring stopped")
            finally:
                checker.disconnect()
    
    elif args.test_comm:
        # Communication test mode
        if checker.connect():
            try:
                success = checker.test_basic_communication()
                sys.exit(0 if success else 1)
            finally:
                checker.disconnect()
    
    else:
        # Full status check
        results = checker.run_full_check()
        
        # Exit with appropriate code
        if results['responsive'] or results['activity_detected']:
            sys.exit(0)
        else:
            sys.exit(1)

if __name__ == "__main__":
    main()

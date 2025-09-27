#!/usr/bin/env python3
"""
i.MX93 Jaguar E-Ink Boot Process Test Script
Tests the boot process after programming via local serial console access

Usage: python3 test_boot_process.py [options]
"""

import sys
import time
import serial
import argparse
import threading
import signal
from datetime import datetime
from typing import Optional, List, Dict

# Default Configuration
DEFAULT_SERIAL_DEVICE = "/dev/ttyUSB1"
DEFAULT_BAUD_RATE = 115200
DEFAULT_TIMEOUT = 30
BOOT_TIMEOUT = 120  # 2 minutes for full boot

# Colors for output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    NC = '\033[0m'  # No Color

def print_status(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.GREEN}[{timestamp}] [INFO]{Colors.NC} {msg}", flush=True)

def print_warning(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.YELLOW}[{timestamp}] [WARN]{Colors.NC} {msg}", flush=True)

def print_error(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.RED}[{timestamp}] [ERROR]{Colors.NC} {msg}", flush=True)

def print_boot_stage(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.BLUE}[{timestamp}] [BOOT]{Colors.NC} {msg}", flush=True)

def print_kernel(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.CYAN}[{timestamp}] [KERNEL]{Colors.NC} {msg}", flush=True)

def print_success(msg: str):
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"{Colors.MAGENTA}[{timestamp}] [SUCCESS]{Colors.NC} {msg}", flush=True)

class BootStageTracker:
    """Track boot stages and timing"""
    def __init__(self):
        self.stages = {}
        self.start_time = None
        self.current_stage = None
    
    def start_tracking(self):
        self.start_time = time.time()
        print_status("Boot stage tracking started")
    
    def mark_stage(self, stage_name: str, description: str = ""):
        if self.start_time is None:
            self.start_tracking()
        
        current_time = time.time()
        elapsed = current_time - self.start_time
        
        self.stages[stage_name] = {
            'time': elapsed,
            'description': description,
            'timestamp': datetime.now()
        }
        
        self.current_stage = stage_name
        print_boot_stage(f"Stage: {stage_name} ({elapsed:.1f}s) - {description}")
    
    def get_summary(self) -> str:
        if not self.stages:
            return "No boot stages tracked"
        
        summary = "\n=== BOOT TIMING SUMMARY ===\n"
        for stage, info in self.stages.items():
            summary += f"{info['time']:6.1f}s - {stage}: {info['description']}\n"
        
        total_time = max(info['time'] for info in self.stages.values())
        summary += f"\nTotal boot time: {total_time:.1f} seconds"
        return summary

class IMX93BootTester:
    def __init__(self, device: str = DEFAULT_SERIAL_DEVICE, baud: int = DEFAULT_BAUD_RATE):
        self.device = device
        self.baud = baud
        self.serial_conn = None
        self.monitoring = False
        self.boot_tracker = BootStageTracker()
        self.boot_log = []
        self.boot_success = False
        self.kernel_panic = False
        self.login_prompt = False
        
        # Boot stage patterns to detect
        self.boot_patterns = {
            'spl_start': ['U-Boot SPL', 'SOC:', 'LC:'],
            'uboot_start': ['U-Boot 20', 'Hit any key to stop autoboot'],
            'kernel_start': ['Starting kernel', 'Linux version'],
            'kernel_init': ['Kernel command line:', 'Memory:'],
            'systemd_start': ['systemd[1]:', 'Welcome to'],
            'services_start': ['Started', 'Reached target'],
            'login_ready': ['login:', 'Welcome to LmP', 'fio login:'],
            'boot_complete': ['multi-user.target', 'graphical.target']
        }
        
        # Error patterns to detect
        self.error_patterns = {
            'kernel_panic': ['Kernel panic', 'Oops:', 'BUG:', 'Unable to handle'],
            'rcu_stall': ['rcu: INFO: rcu_preempt self-detected stall'],
            'ele_error': ['fsl-ele-mu', 'failed to init reserved memory region'],
            'timeout': ['Timeout', 'timeout'],
            'crash': ['Segmentation fault', 'segfault', 'SIGSEGV']
        }
    
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
            cmd_bytes = (command + '\n').encode('utf-8')
            self.serial_conn.write(cmd_bytes)
            self.serial_conn.flush()
            print_status(f"Sent command: {command}")
            return True
        except Exception as e:
            print_error(f"Failed to send command '{command}': {e}")
            return False
    
    def read_line(self, timeout: float = 1.0) -> Optional[str]:
        """Read a line from serial port with timeout"""
        if not self.serial_conn or not self.serial_conn.is_open:
            return None
        
        try:
            # Set timeout for this read
            old_timeout = self.serial_conn.timeout
            self.serial_conn.timeout = timeout
            
            line = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
            
            # Restore original timeout
            self.serial_conn.timeout = old_timeout
            
            return line if line else None
            
        except Exception as e:
            print_error(f"Error reading from serial: {e}")
            return None
    
    def analyze_boot_line(self, line: str):
        """Analyze a boot log line for stages and errors"""
        if not line:
            return
        
        # Store in boot log
        self.boot_log.append(f"[{datetime.now().strftime('%H:%M:%S')}] {line}")
        
        # Check for boot stages
        for stage, patterns in self.boot_patterns.items():
            for pattern in patterns:
                if pattern in line:
                    if stage == 'spl_start':
                        self.boot_tracker.mark_stage(stage, "U-Boot SPL starting")
                    elif stage == 'uboot_start':
                        self.boot_tracker.mark_stage(stage, "U-Boot main starting")
                    elif stage == 'kernel_start':
                        self.boot_tracker.mark_stage(stage, "Linux kernel starting")
                    elif stage == 'kernel_init':
                        self.boot_tracker.mark_stage(stage, "Kernel initialization")
                    elif stage == 'systemd_start':
                        self.boot_tracker.mark_stage(stage, "Systemd starting")
                    elif stage == 'services_start':
                        self.boot_tracker.mark_stage(stage, "System services starting")
                    elif stage == 'login_ready':
                        self.boot_tracker.mark_stage(stage, "Login prompt ready")
                        self.login_prompt = True
                        self.boot_success = True
                    elif stage == 'boot_complete':
                        self.boot_tracker.mark_stage(stage, "Boot process complete")
                        self.boot_success = True
                    break
        
        # Check for errors
        for error_type, patterns in self.error_patterns.items():
            for pattern in patterns:
                if pattern in line:
                    if error_type == 'kernel_panic':
                        self.kernel_panic = True
                        print_error(f"KERNEL PANIC detected: {line}")
                    elif error_type == 'rcu_stall':
                        print_error(f"RCU STALL detected: {line}")
                    elif error_type == 'ele_error':
                        print_error(f"ELE ERROR detected: {line}")
                    else:
                        print_warning(f"{error_type.upper()} detected: {line}")
                    break
    
    def monitor_boot_process(self, timeout: int = BOOT_TIMEOUT) -> bool:
        """Monitor the boot process"""
        print_status(f"Monitoring boot process for up to {timeout} seconds...")
        print_status("Waiting for board to start booting...")
        
        self.monitoring = True
        self.boot_tracker.start_tracking()
        start_time = time.time()
        
        try:
            while self.monitoring and (time.time() - start_time) < timeout:
                line = self.read_line(timeout=1.0)
                
                if line:
                    # Print the line with appropriate coloring
                    if any(pattern in line for pattern in ['U-Boot SPL', 'U-Boot 20']):
                        print_boot_stage(line)
                    elif any(pattern in line for pattern in ['Linux version', 'Kernel command line']):
                        print_kernel(line)
                    elif any(pattern in line for pattern in ['systemd', 'Started', 'Reached target']):
                        print_status(line)
                    elif any(pattern in line for pattern in ['login:', 'Welcome to']):
                        print_success(line)
                    elif any(pattern in line for pattern in ['panic', 'Oops', 'BUG', 'Error', 'Failed']):
                        print_error(line)
                    else:
                        print(f"  {line}")
                    
                    # Analyze the line
                    self.analyze_boot_line(line)
                    
                    # Check if boot completed successfully
                    if self.boot_success:
                        print_success("Boot process completed successfully!")
                        break
                    
                    # Check for critical errors
                    if self.kernel_panic:
                        print_error("Boot failed due to kernel panic")
                        break
                
                # Small delay to prevent CPU spinning
                time.sleep(0.01)
        
        except KeyboardInterrupt:
            print_warning("Boot monitoring interrupted by user")
            self.monitoring = False
        
        elapsed = time.time() - start_time
        
        if self.boot_success:
            print_success(f"Boot monitoring completed successfully in {elapsed:.1f} seconds")
        elif self.kernel_panic:
            print_error(f"Boot monitoring failed due to kernel panic after {elapsed:.1f} seconds")
        elif elapsed >= timeout:
            print_error(f"Boot monitoring timed out after {timeout} seconds")
        else:
            print_warning(f"Boot monitoring stopped after {elapsed:.1f} seconds")
        
        return self.boot_success
    
    def test_login_interaction(self) -> bool:
        """Test basic login interaction if login prompt is available"""
        if not self.login_prompt:
            print_warning("No login prompt detected, skipping login test")
            return False
        
        print_status("Testing login interaction...")
        
        # Try to send username
        if self.send_command("fio"):
            time.sleep(1)
            
            # Look for password prompt
            for _ in range(5):
                line = self.read_line(timeout=2.0)
                if line and "password" in line.lower():
                    print_status("Password prompt detected")
                    
                    # Send password
                    if self.send_command("fio"):
                        time.sleep(2)
                        
                        # Look for shell prompt
                        for _ in range(5):
                            line = self.read_line(timeout=2.0)
                            if line and any(prompt in line for prompt in ["$", "#", "fio@"]):
                                print_success("Successfully logged in!")
                                return True
                        
                        print_warning("Login attempted but no shell prompt detected")
                        return False
                    else:
                        print_error("Failed to send password")
                        return False
        
        print_error("Failed to interact with login prompt")
        return False
    
    def save_boot_log(self, filename: str = None):
        """Save boot log to file"""
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"boot_log_{timestamp}.txt"
        
        try:
            with open(filename, 'w') as f:
                f.write("=== i.MX93 Jaguar E-Ink Boot Log ===\n")
                f.write(f"Test started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Serial device: {self.device}\n")
                f.write(f"Baud rate: {self.baud}\n\n")
                
                f.write("=== Boot Timing Summary ===\n")
                f.write(self.boot_tracker.get_summary())
                f.write("\n\n")
                
                f.write("=== Full Boot Log ===\n")
                for line in self.boot_log:
                    f.write(line + '\n')
            
            print_status(f"Boot log saved to: {filename}")
            return filename
            
        except Exception as e:
            print_error(f"Failed to save boot log: {e}")
            return None
    
    def run_full_boot_test(self, timeout: int = BOOT_TIMEOUT, save_log: bool = True) -> Dict:
        """Run complete boot test"""
        print("=" * 80)
        print("i.MX93 JAGUAR E-INK BOOT PROCESS TEST")
        print("=" * 80)
        
        results = {
            'success': False,
            'boot_time': 0,
            'stages_completed': 0,
            'login_available': False,
            'errors_detected': [],
            'log_file': None
        }
        
        if not self.connect():
            results['errors_detected'].append('Serial connection failed')
            return results
        
        try:
            # Monitor boot process
            boot_success = self.monitor_boot_process(timeout)
            
            results['success'] = boot_success
            results['stages_completed'] = len(self.boot_tracker.stages)
            results['login_available'] = self.login_prompt
            
            if self.boot_tracker.stages:
                max_time = max(info['time'] for info in self.boot_tracker.stages.values())
                results['boot_time'] = max_time
            
            # Collect errors
            if self.kernel_panic:
                results['errors_detected'].append('Kernel panic')
            
            # Test login if available
            if self.login_prompt:
                login_success = self.test_login_interaction()
                results['login_success'] = login_success
            
            # Save log
            if save_log:
                log_file = self.save_boot_log()
                results['log_file'] = log_file
            
            # Print summary
            print("\n" + "=" * 80)
            print("BOOT TEST SUMMARY")
            print("=" * 80)
            print(self.boot_tracker.get_summary())
            
            if boot_success:
                print_success(f"\n✅ Boot test PASSED - System booted successfully")
            else:
                print_error(f"\n❌ Boot test FAILED - System did not boot properly")
            
            if results['errors_detected']:
                print_error(f"Errors detected: {', '.join(results['errors_detected'])}")
            
            print("=" * 80)
            
        finally:
            self.disconnect()
        
        return results

def main():
    parser = argparse.ArgumentParser(description="i.MX93 Jaguar E-Ink Boot Process Test")
    parser.add_argument("-d", "--device", default=DEFAULT_SERIAL_DEVICE,
                       help=f"Serial device (default: {DEFAULT_SERIAL_DEVICE})")
    parser.add_argument("-b", "--baud", type=int, default=DEFAULT_BAUD_RATE,
                       help=f"Baud rate (default: {DEFAULT_BAUD_RATE})")
    parser.add_argument("-t", "--timeout", type=int, default=BOOT_TIMEOUT,
                       help=f"Boot timeout in seconds (default: {BOOT_TIMEOUT})")
    parser.add_argument("--no-log", action="store_true",
                       help="Don't save boot log to file")
    parser.add_argument("--monitor-only", action="store_true",
                       help="Only monitor output, don't analyze boot stages")
    
    args = parser.parse_args()
    
    print_status(f"Starting i.MX93 boot test on {args.device}")
    print_status("Make sure the board is in boot mode (not programming mode)")
    print_status("Press Ctrl+C to stop monitoring\n")
    
    tester = IMX93BootTester(device=args.device, baud=args.baud)
    
    if args.monitor_only:
        # Simple monitoring mode
        if tester.connect():
            try:
                print_status("Monitoring serial output (Ctrl+C to stop)...")
                while True:
                    line = tester.read_line(timeout=1.0)
                    if line:
                        print(line)
            except KeyboardInterrupt:
                print_status("\nMonitoring stopped")
            finally:
                tester.disconnect()
    else:
        # Full boot test
        results = tester.run_full_boot_test(timeout=args.timeout, save_log=not args.no_log)
        
        # Exit with appropriate code
        sys.exit(0 if results['success'] else 1)

if __name__ == "__main__":
    main()

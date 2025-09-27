#!/usr/bin/env python3
"""
i.MX93 Jaguar E-Ink Interactive Serial Console
Interactive terminal for communicating with the board via local serial console

Usage: python3 serial_console.py [options]
"""

import sys
import time
import serial
import argparse
import threading
import select
import termios
import tty
from datetime import datetime

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
    MAGENTA = '\033[95m'
    NC = '\033[0m'

class SerialConsole:
    def __init__(self, device: str = DEFAULT_SERIAL_DEVICE, baud: int = DEFAULT_BAUD_RATE):
        self.device = device
        self.baud = baud
        self.serial_conn = None
        self.running = False
        self.log_file = None
        self.timestamp_enabled = False
        
        # Terminal settings
        self.old_settings = None
    
    def connect(self) -> bool:
        """Connect to serial port"""
        try:
            print(f"{Colors.GREEN}[INFO]{Colors.NC} Connecting to {self.device} at {self.baud} baud...")
            self.serial_conn = serial.Serial(
                port=self.device,
                baudrate=self.baud,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=0.1,  # Non-blocking
                xonxoff=False,
                rtscts=False,
                dsrdtr=False
            )
            
            print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} Connected to {self.device}")
            print(f"{Colors.CYAN}[INFO]{Colors.NC} Press Ctrl+] to exit, Ctrl+L to toggle logging")
            print(f"{Colors.CYAN}[INFO]{Colors.NC} Press Ctrl+T to toggle timestamps")
            print("-" * 60)
            return True
            
        except Exception as e:
            print(f"{Colors.RED}[ERROR]{Colors.NC} Failed to connect to {self.device}: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from serial port"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            print(f"\n{Colors.GREEN}[INFO]{Colors.NC} Serial connection closed")
        
        if self.log_file:
            self.log_file.close()
            print(f"{Colors.GREEN}[INFO]{Colors.NC} Log file closed")
    
    def setup_terminal(self):
        """Setup terminal for raw input"""
        if sys.stdin.isatty():
            self.old_settings = termios.tcgetattr(sys.stdin)
            tty.setraw(sys.stdin.fileno())
    
    def restore_terminal(self):
        """Restore terminal settings"""
        if self.old_settings:
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.old_settings)
    
    def start_logging(self, filename: str = None):
        """Start logging to file"""
        if self.log_file:
            self.log_file.close()
        
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"serial_log_{timestamp}.txt"
        
        try:
            self.log_file = open(filename, 'w')
            self.log_file.write(f"=== Serial Console Log Started ===\n")
            self.log_file.write(f"Device: {self.device}\n")
            self.log_file.write(f"Baud: {self.baud}\n")
            self.log_file.write(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            self.log_file.write("=" * 40 + "\n")
            self.log_file.flush()
            
            print(f"\n{Colors.GREEN}[LOG]{Colors.NC} Logging started: {filename}")
            return True
            
        except Exception as e:
            print(f"\n{Colors.RED}[ERROR]{Colors.NC} Failed to start logging: {e}")
            return False
    
    def stop_logging(self):
        """Stop logging"""
        if self.log_file:
            self.log_file.write(f"\n=== Log Ended: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n")
            self.log_file.close()
            self.log_file = None
            print(f"\n{Colors.GREEN}[LOG]{Colors.NC} Logging stopped")
    
    def log_data(self, data: str, direction: str = "RX"):
        """Log data to file if logging is enabled"""
        if self.log_file:
            timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]  # Include milliseconds
            self.log_file.write(f"[{timestamp}] {direction}: {repr(data)}\n")
            self.log_file.flush()
    
    def read_serial_thread(self):
        """Thread to read from serial port"""
        while self.running:
            try:
                if self.serial_conn and self.serial_conn.is_open and self.serial_conn.in_waiting > 0:
                    data = self.serial_conn.read(self.serial_conn.in_waiting)
                    if data:
                        text = data.decode('utf-8', errors='replace')
                        
                        # Log the data
                        self.log_data(text, "RX")
                        
                        # Print with optional timestamp
                        if self.timestamp_enabled:
                            lines = text.split('\n')
                            for i, line in enumerate(lines):
                                if line or i < len(lines) - 1:  # Don't timestamp empty last line
                                    timestamp = datetime.now().strftime('%H:%M:%S')
                                    if line:
                                        print(f"{Colors.BLUE}[{timestamp}]{Colors.NC} {line}")
                                    else:
                                        print()  # Just newline
                        else:
                            print(text, end='', flush=True)
                
                time.sleep(0.01)  # Small delay to prevent CPU spinning
                
            except Exception as e:
                if self.running:  # Only print error if we're still supposed to be running
                    print(f"\n{Colors.RED}[ERROR]{Colors.NC} Serial read error: {e}")
                break
    
    def handle_special_keys(self, char: str) -> bool:
        """Handle special key combinations"""
        if char == '\x1d':  # Ctrl+]
            print(f"\n{Colors.YELLOW}[INFO]{Colors.NC} Exit requested")
            return False
        elif char == '\x0c':  # Ctrl+L
            if self.log_file:
                self.stop_logging()
            else:
                self.start_logging()
            return True
        elif char == '\x14':  # Ctrl+T
            self.timestamp_enabled = not self.timestamp_enabled
            status = "enabled" if self.timestamp_enabled else "disabled"
            print(f"\n{Colors.CYAN}[INFO]{Colors.NC} Timestamps {status}")
            return True
        
        return True
    
    def run_interactive(self):
        """Run interactive console"""
        if not self.connect():
            return False
        
        self.running = True
        
        # Setup terminal for raw input
        self.setup_terminal()
        
        try:
            # Start serial reading thread
            read_thread = threading.Thread(target=self.read_serial_thread, daemon=True)
            read_thread.start()
            
            # Main input loop
            while self.running:
                if sys.stdin in select.select([sys.stdin], [], [], 0.1)[0]:
                    char = sys.stdin.read(1)
                    
                    if not char:  # EOF
                        break
                    
                    # Handle special keys
                    if not self.handle_special_keys(char):
                        break
                    
                    # Send character to serial port
                    if self.serial_conn and self.serial_conn.is_open:
                        try:
                            self.serial_conn.write(char.encode('utf-8'))
                            self.serial_conn.flush()
                            
                            # Log the sent data
                            self.log_data(char, "TX")
                            
                        except Exception as e:
                            print(f"\n{Colors.RED}[ERROR]{Colors.NC} Serial write error: {e}")
                            break
        
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}[INFO]{Colors.NC} Interrupted by user")
        
        finally:
            self.running = False
            self.restore_terminal()
            self.disconnect()
        
        return True
    
    def send_file(self, filename: str, delay: float = 0.1):
        """Send file contents to serial port"""
        if not self.serial_conn or not self.serial_conn.is_open:
            print(f"{Colors.RED}[ERROR]{Colors.NC} Serial connection not open")
            return False
        
        try:
            with open(filename, 'r') as f:
                content = f.read()
            
            print(f"{Colors.GREEN}[INFO]{Colors.NC} Sending file: {filename} ({len(content)} bytes)")
            
            for char in content:
                self.serial_conn.write(char.encode('utf-8'))
                self.serial_conn.flush()
                
                # Log the sent data
                self.log_data(char, "TX")
                
                if delay > 0:
                    time.sleep(delay)
            
            print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} File sent successfully")
            return True
            
        except Exception as e:
            print(f"{Colors.RED}[ERROR]{Colors.NC} Failed to send file: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description="i.MX93 Jaguar E-Ink Interactive Serial Console")
    parser.add_argument("-d", "--device", default=DEFAULT_SERIAL_DEVICE,
                       help=f"Serial device (default: {DEFAULT_SERIAL_DEVICE})")
    parser.add_argument("-b", "--baud", type=int, default=DEFAULT_BAUD_RATE,
                       help=f"Baud rate (default: {DEFAULT_BAUD_RATE})")
    parser.add_argument("-l", "--log", metavar="FILENAME",
                       help="Start logging to file immediately")
    parser.add_argument("-t", "--timestamps", action="store_true",
                       help="Enable timestamps on received data")
    parser.add_argument("--send-file", metavar="FILENAME",
                       help="Send file contents to serial port and exit")
    parser.add_argument("--send-delay", type=float, default=0.1,
                       help="Delay between characters when sending file (default: 0.1s)")
    
    args = parser.parse_args()
    
    console = SerialConsole(device=args.device, baud=args.baud)
    
    if args.timestamps:
        console.timestamp_enabled = True
    
    if args.send_file:
        # File sending mode
        if console.connect():
            if args.log:
                console.start_logging(args.log)
            
            success = console.send_file(args.send_file, args.send_delay)
            console.disconnect()
            sys.exit(0 if success else 1)
    else:
        # Interactive mode
        print("=" * 60)
        print("i.MX93 JAGUAR E-INK INTERACTIVE SERIAL CONSOLE")
        print("=" * 60)
        print(f"Device: {args.device}")
        print(f"Baud Rate: {args.baud}")
        print()
        print("Control Keys:")
        print("  Ctrl+]  - Exit console")
        print("  Ctrl+L  - Toggle logging")
        print("  Ctrl+T  - Toggle timestamps")
        print()
        
        if args.log:
            console.start_logging(args.log)
        
        success = console.run_interactive()
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()

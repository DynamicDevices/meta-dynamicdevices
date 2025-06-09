#!/usr/bin/env python

#
# Copyright (c) SynchronicIT B.V. 2022. All rights reserved.                           09/08/2022
#             _____                  _               ______         _             
#            / ____|                | |             |  ____|       (_)             TM
#           | (___  _   _ _ __   ___| |__  _ __ ___ | |__ _   _ ___ _  ___  _ __  
#            \___ \| | | | '_ \ / __| '_ \| '__/ _ \|  __| | | / __| |/ _ \| '_ \ 
#            ____) | |_| | | | | (__| | | | | | (_) | |  | |_| \__ \ | (_) | | | |
#           |_____/ \__, |_| |_|\___|_| |_|_|  \___/|_|   \__,_|___/_|\___/|_| |_|
#                    __/ |                                                        
#                   |___/                                 http://www.synchronicit.nl/ 
#
#  This software is confidential and proprietary of SynchronicIT and is subject to the terms and 
#  conditions defined in file 'LICENSE.txt', which is part of this source code package. You shall 
#  not disclose such Confidential Information and shall use it only in accordance with the terms 
#  of the license agreement.
#
# Portions including MQTT publishing functionality and enhanced logging features
# Copyright (c) Dynamic Devices Ltd. 2025. All rights reserved.
#

import struct
import serial
import argparse
import time
import math
import json
import ssl
import sys

# MQTT imports
try:
    import paho.mqtt.client as mqtt
except ImportError as e:
    print("Error: paho-mqtt library not found. Install with: pip install paho-mqtt")
    sys.exit(1)

parser = argparse.ArgumentParser(description='Sketch flash loader with MQTT publishing')
parser.add_argument("uart", help="uart port to use", type=str, default="/dev/ttyUSB0", nargs='?')
parser.add_argument("nodes", help="node lists",type=str, default="[]", nargs='?')
parser.add_argument("--mqtt-broker", help="MQTT broker hostname", type=str, default="mqtt.dynamicdevices.co.uk")
parser.add_argument("--mqtt-port", help="MQTT broker port", type=int, default=8883)
parser.add_argument("--mqtt-topic", help="MQTT topic to publish to", type=str, default="uwb/positions")
parser.add_argument("--mqtt-rate-limit", help="Minimum seconds between MQTT publishes", type=float, default=10.0)
parser.add_argument("--disable-mqtt", help="Disable MQTT publishing", action="store_true")
parser.add_argument("--verbose", help="Enable verbose logging", action="store_true")
parser.add_argument("--quiet", help="Enable quiet mode (minimal logging)", action="store_true")

args = parser.parse_args()

# MQTT globals
mqtt_client = None
last_publish_time = 0

# Error tracking globals
parsing_error_count = 0
MAX_PARSING_ERRORS = 3

# Rate limiting globals - thread-safe access
import threading
rate_limit_lock = threading.Lock()
current_rate_limit = 10.0  # Will be set from args.mqtt_rate_limit

def log_info(message):
    """Always print important info unless in quiet mode"""
    if not args.quiet:
        print(message)

def log_verbose(message):
    """Only print in verbose mode"""
    if args.verbose:
        print(f"[VERBOSE] {message}")

def log_warning(message):
    """Always print warnings unless in quiet mode"""
    if not args.quiet:
        print(f"[WARNING] {message}")

def log_error(message):
    """Always print errors"""
    print(f"[ERROR] {message}")

def log_start(message):
    """Always print startup messages"""
    print(message)

def on_mqtt_connect(client, userdata, flags, rc):
    log_verbose(f"MQTT connect callback: flags={flags}, rc={rc}")
    if rc == 0:
        log_info(f"Connected to MQTT broker {args.mqtt_broker}:{args.mqtt_port}")
        log_verbose("MQTT connection successful")
        
        # Subscribe to command topic for rate limit updates
        command_topic = f"{args.mqtt_topic}/cmd"
        try:
            client.subscribe(command_topic, qos=1)
            log_info(f"Subscribed to command topic: {command_topic}")
        except Exception as e:
            log_error(f"Failed to subscribe to command topic: {e}")
    else:
        error_messages = {
            1: "Connection refused - incorrect protocol version",
            2: "Connection refused - invalid client identifier",
            3: "Connection refused - server unavailable",
            4: "Connection refused - bad username or password",
            5: "Connection refused - not authorised"
        }
        error_msg = error_messages.get(rc, f"Unknown error code {rc}")
        log_error(f"Failed to connect to MQTT broker: {error_msg}")
        log_verbose(f"MQTT connection failed with detailed error: {error_msg}")

def on_mqtt_disconnect(client, userdata, rc):
    log_verbose(f"MQTT disconnect callback: rc={rc}")
    if rc != 0:
        log_warning("Unexpected disconnection from MQTT broker")
        log_verbose("MQTT unexpected disconnection")
    else:
        log_info("Disconnected from MQTT broker")
        log_verbose("MQTT clean disconnection")

def on_mqtt_publish(client, userdata, mid):
    log_verbose(f"Message {mid} published to MQTT successfully")

def on_mqtt_log(client, userdata, level, buf):
    if args.verbose:
        print(f"[MQTT LOG] {buf}")

def on_mqtt_message(client, userdata, message):
    """Handle incoming MQTT command messages"""
    try:
        topic = message.topic
        payload = message.payload.decode('utf-8').strip()
        
        log_verbose(f"Received command on {topic}: {payload}")
        
        # Parse rate limit commands
        if payload.startswith('set rate_limit '):
            try:
                new_rate = float(payload.split(' ')[2])
                if new_rate > 0:
                    global current_rate_limit
                    with rate_limit_lock:
                        old_rate = current_rate_limit
                        current_rate_limit = new_rate
                    log_info(f"Updated rate limit: {old_rate}s → {new_rate}s")
                else:
                    log_warning(f"Invalid rate limit value: {new_rate} (must be > 0)")
            except (IndexError, ValueError) as e:
                log_warning(f"Failed to parse rate limit command: {payload}")
        else:
            log_verbose(f"Unknown command: {payload}")
            
    except Exception as e:
        log_error(f"Error processing MQTT command: {e}")

def setup_mqtt():
    global mqtt_client, current_rate_limit
    
    if args.disable_mqtt:
        log_verbose("MQTT disabled via command line argument")
        return None
        
    # Initialize current rate limit from command line argument
    current_rate_limit = args.mqtt_rate_limit
    
    if args.disable_mqtt:
        log_verbose("MQTT disabled via command line argument")
        return None
        
    try:
        log_verbose("Creating MQTT client instance")
        mqtt_client = mqtt.Client()
        
        # Set up callbacks
        mqtt_client.on_connect = on_mqtt_connect
        mqtt_client.on_disconnect = on_mqtt_disconnect
        mqtt_client.on_publish = on_mqtt_publish
        mqtt_client.on_log = on_mqtt_log
        mqtt_client.on_message = on_mqtt_message
        
        log_verbose(f"Configuring SSL for broker {args.mqtt_broker}:{args.mqtt_port}")
        
        # Configure SSL
        context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        
        log_verbose(f"SSL context created - check_hostname={context.check_hostname}, verify_mode={context.verify_mode}")
        
        mqtt_client.tls_set_context(context)
        log_verbose("SSL context applied to MQTT client")
        
        # Connect to broker
        log_verbose(f"Attempting to connect to {args.mqtt_broker}:{args.mqtt_port}")
        connect_result = mqtt_client.connect(args.mqtt_broker, args.mqtt_port, 60)
        log_verbose(f"Connect call returned: {connect_result}")
        
        log_verbose("Starting MQTT client loop")
        mqtt_client.loop_start()
        
        # Wait a moment for connection to establish
        time.sleep(2)
        
        if mqtt_client.is_connected():
            log_verbose("MQTT client reports connected status")
        else:
            log_verbose("MQTT client reports disconnected status after 2 seconds")
        
        log_info(f"MQTT client configured for {args.mqtt_broker}:{args.mqtt_port}")
        return mqtt_client
        
    except Exception as e:
        log_error(f"Failed to setup MQTT: {e}")
        log_verbose(f"MQTT setup exception details: {type(e).__name__}: {str(e)}")
        import traceback
        if args.verbose:
            traceback.print_exc()
        return None

def publish_to_mqtt(data):
    global mqtt_client, last_publish_time
    
    if mqtt_client is None:
        log_info("MQTT publish skipped - client not available")
        return
        
    if args.disable_mqtt:
        log_verbose("MQTT publish skipped - disabled via command line")
        return
        
    current_time = time.time()
    time_since_last = current_time - last_publish_time
    
    # Get current rate limit in thread-safe manner
    with rate_limit_lock:
        rate_limit = current_rate_limit
    
    if time_since_last < rate_limit:
        log_info(f"MQTT publish rate limited - waiting {rate_limit - time_since_last:.1f}s more")
        return
        
    if not mqtt_client.is_connected():
        log_info("MQTT client not connected, skipping publish")
        return
        
    try:
        # Convert data to JSON string with proper formatting
        json_data = json.dumps(data)
        log_verbose(f"Attempting to publish to topic '{args.mqtt_topic}': {json_data}")
        
        result = mqtt_client.publish(args.mqtt_topic, json_data, qos=1)
        log_verbose(f"Publish result: rc={result.rc}, mid={result.mid}")
        
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            last_publish_time = current_time
            log_info(f"Published to MQTT topic '{args.mqtt_topic}': {json_data}")
        else:
            error_messages = {
                mqtt.MQTT_ERR_NO_CONN: "No connection to broker",
                mqtt.MQTT_ERR_QUEUE_SIZE: "Message queue full",
                mqtt.MQTT_ERR_PAYLOAD_SIZE: "Payload too large"
            }
            error_msg = error_messages.get(result.rc, f"Unknown error {result.rc}")
            log_info(f"Failed to publish to MQTT: {error_msg}")
            
    except Exception as e:
        log_info(f"Error publishing to MQTT: {e}")
        log_verbose(f"MQTT publish exception: {type(e).__name__}: {str(e)}")
        if args.verbose:
            import traceback
            traceback.print_exc()

def connect(uart):
    try:
        ser = serial.serial_for_url(uart, do_not_open=True)
        ser.baudrate = 115200
        ser.bytesize = 8
        ser.parity = 'N'
        ser.stopbits = 1
        ser.rtscts = False
        ser.xonxoff = False
        ser.open()
        ser.dtr = False
        
    except serial.SerialException as e:
        log_error(f"Serial connection failed: {e}")
        return 0
    
    time.sleep(0.5)
    log_verbose(f"Serial connection established: {ser.read(ser.in_waiting)}")

    return ser

def disconnect(ser): 
    ser.rts = False  
    ser.close()
    ser.is_open = False

def flush_rx(ser):
    try:
        n = ser.in_waiting
        msg = ser.read(n)
        return msg
        
    except serial.SerialException as e:
        log_error(f"Serial read error: {e}")
        disconnect(ser)
        return b''

def reset(ser):
    global parsing_error_count
    log_info("Resetting device...")
    ser.dtr = True
    time.sleep(0.1)
    ser.dtr = False
    parsing_error_count = 0  # Reset error counter after device reset

def write(d, data):
    s = str(bytearray(data)) if sys.version_info<(3,) else bytes(data)
    return d.write(s)

def read(d, nbytes):
    s = d.read(nbytes)
    return [ord(c) for c in s] if type(s) is str else list(s)

def twr_value_ok(value):
    return value > 0 and 0.004690384 * value < 300

def handle_parsing_error(error_msg):
    global parsing_error_count
    parsing_error_count += 1
    log_warning(f"Packet parsing error ({parsing_error_count}/{MAX_PARSING_ERRORS}): {error_msg}")
    
    if parsing_error_count >= MAX_PARSING_ERRORS:
        log_warning(f"Maximum parsing errors reached ({MAX_PARSING_ERRORS}), resetting device...")
        return True  # Signal that reset is needed
    return False

def parse_final(assignments, final_payload, mode=0):
    results = []

    if len(final_payload) == 0:
        return results
    
    try:
        idx = 0

        for i in range(0, len(assignments[0])):
            for j in range(0, len(assignments[1])):
                if idx + 2 > len(final_payload):
                    raise ValueError("Insufficient payload data for assignments[0] x assignments[1]")
                value = struct.unpack('<H', final_payload[idx:(idx+2)])[0]
                idx += 2
                if (twr_value_ok(value)):
                    results.append([assignments[0][i], assignments[1][j], 0.004690384 * (value)])
        
        for i in range(0, len(assignments[0])):
            for j in range(0, len(assignments[2])):
                if idx + 2 > len(final_payload):
                    raise ValueError("Insufficient payload data for assignments[0] x assignments[2]")
                value = struct.unpack('<H', final_payload[idx:(idx+2)])[0]
                idx += 2
                if (twr_value_ok(value)):
                    results.append([assignments[0][i], assignments[2][j], 0.004690384 * (value)])

        for i in range(0, len(assignments[1])):
            for j in range(0, len(assignments[2])):
                if idx + 2 > len(final_payload):
                    raise ValueError("Insufficient payload data for assignments[1] x assignments[2]")
                value = struct.unpack('<H', final_payload[idx:(idx+2)])[0]
                idx += 2
                if (twr_value_ok(value)):
                    results.append([assignments[1][i], assignments[2][j], 0.004690384 * (value)])

        if mode & 1:
            for i in range(0, len(assignments[0])):
                for j in range(i+1, len(assignments[0])):
                    if idx + 2 > len(final_payload):
                        raise ValueError("Insufficient payload data for assignments[0] internal")
                    value = struct.unpack('<H', final_payload[idx:(idx+2)])[0]
                    idx += 2
                    if (twr_value_ok(value)):
                        results.append([assignments[0][i], assignments[0][j], 0.004690384 * (value)])
        
        if mode & 2:
            for i in range(0, len(assignments[1])):
                for j in range(i+1, len(assignments[1])):
                    if idx + 2 > len(final_payload):
                        raise ValueError("Insufficient payload data for assignments[1] internal")
                    value = struct.unpack('<H', final_payload[idx:(idx+2)])[0]
                    idx += 2
                    if (twr_value_ok(value)):
                        results.append([assignments[1][i], assignments[1][j], 0.004690384 * (value)])
                    
    except (struct.error, ValueError, IndexError) as e:
        if handle_parsing_error(f"parse_final: {str(e)}"):
            raise Exception("RESET_REQUIRED")
        return []
                
    return results

def print_list(results):
    if len(results) == 0:
        return
        
    # Format data for both display and MQTT publishing
    formatted_data = []
    row = "[ "
    
    for item in results:
        # Create formatted entry for MQTT (with quoted node IDs)
        mqtt_entry = ["{:04X}".format(item[0]), "{:04X}".format(item[1]), round(item[2], 3)]
        formatted_data.append(mqtt_entry)
        
        # Create display string
        row += "[\"{:04X}\",".format( item[0] )
        row += "\"{:04X}\",".format( item[1] )
        row += "{: <3.3f}], ".format( item[2] )
        
    row = row[:-2]
    row += " ]"
    
    # Only show parsed data in verbose mode
    log_verbose(f"Parsed data: {row}")
    
    # Publish to MQTT
    publish_to_mqtt(formatted_data)

def print_matrix(assignments, results):
    if not args.verbose:
        return
        
    nodes = []
    for a in assignments:
        for node in a:
            nodes.append(node)
        
    result_matrix = []
    for i in range(0, len(nodes)):
        row = []
        for j in range(0, len(nodes)):
            row.append(-1)
        result_matrix.append(row)

        
    for result in results:
        i = nodes.index(result[0])
        j = nodes.index(result[1])
        result_matrix[i][j] = result[2]

    row = "        "
    for node in nodes:
        row += "{:04X}    ".format( node )
    log_verbose(row)

    rowIdx = 0  
    for lst in result_matrix:
        row = "{:04X}    ".format( nodes[rowIdx] )
        rowIdx = rowIdx + 1
        for item in lst:
            if item == -1:
                row += "        "
            else:
                row += "{: <8.3f}".format( item )
        log_verbose(row)

# Print startup information
log_start("UWB MQTT Publisher Starting...")
log_start(f"Serial port: {args.uart}")
log_start(f"MQTT broker: {args.mqtt_broker}:{args.mqtt_port}")
log_start(f"MQTT topic: {args.mqtt_topic}")
log_start(f"MQTT command topic: {args.mqtt_topic}/cmd")
log_start(f"Initial rate limit: {args.mqtt_rate_limit}s")
if args.quiet:
    log_start("Quiet mode enabled - minimal logging")
elif args.verbose:
    log_start("Verbose mode enabled - detailed logging")

# Initialize MQTT
log_verbose("Initializing MQTT client...")
mqtt_client = setup_mqtt()

log_verbose(f"Connecting to serial port {args.uart}")
ser = connect(args.uart)

if not ser:
    log_error("Failed to connect to serial port")
    sys.exit(1)

reset(ser)
time.sleep(0.5)

ser.reset_input_buffer()
if False:
    ser.write([0xdc, 0xac, 1, 0, ord('w')])
    time.sleep(0.5)
    log_verbose(f"Write response: {flush_rx(ser)}")

ser.write([0xdc, 0xac, 1, 0, ord('s')])

if False:
    time.sleep(0.5)
    log_verbose(f"Start response: {flush_rx(ser)}")

s = []

assignments = []
tof_list = []
n = 3
mode = 0
g1 = 0
g2 = 0
g3 = 0
unassigned_count = 0

log_start("Data processing started...")

try:
    while(1):

        cnt = ser.in_waiting
        if cnt > 0:
            newS = read(ser, 1)
            
            s = s + newS
            
            while len(s) >= 4:
                try:
                    if s[0] == 0xDC and  s[1] == 0xAC:
                        l = struct.unpack('<H', bytes(s[2:4]))[0]

                        payload = read(ser, l)
                        s = []
                        idx = 0
                        
                        if len(payload) < 4:
                            raise ValueError("Payload too short")
                            
                        [act_type, act_slot, timeframe] = struct.unpack('<BbH', bytes(payload[idx:(idx+4)]))
                        log_verbose(f"act_type: {hex(act_type)}: {act_slot}/{timeframe}")
                        idx = idx + 4

                        if (payload[0] == 2):
                            assignments = []
                            if len(payload) < idx + 5:
                                raise ValueError("Assignment payload too short")
                                
                            [tx_pwr, mode, g1, g2, g3] = struct.unpack('<BBBBB', bytes(payload[idx:(idx+5)]))

                            log_verbose(f"mode: {hex(mode)}: {g1}/{g2}/{g3}")

                            idx = idx + 5
                            group1 = []
                            for i in range(0, g1):
                                if idx + 2 > len(payload):
                                    raise ValueError("Group1 data incomplete")
                                group1.append(struct.unpack('<H', bytes(payload[idx:(idx+2)]))[0])
                                idx = idx + 2
                            group2 = []
                            for i in range(0, g2):
                                if idx + 2 > len(payload):
                                    raise ValueError("Group2 data incomplete")
                                group2.append(struct.unpack('<H', bytes(payload[idx:(idx+2)]))[0])
                                idx = idx + 2
                            group3 = []
                            
                            unassigned_count = 0
                            for i in range(0, g3):
                                if idx + 2 > len(payload):
                                    raise ValueError("Group3 data incomplete")
                                id = struct.unpack('<H', bytes(payload[idx:(idx+2)]))[0]
                                if id == 0:
                                    unassigned_count = unassigned_count + 1
                                group3.append(id)
                                idx = idx + 2
                            assignments = [group1, group2, group3]

                            log_verbose(f"Assignments: {assignments}")

                        if (payload[0] == 4):
                            tof_list = []

                            tof_count = g1 * g2 + g1 * g3 + g2 * g3
                            if mode & 1:
                                tof_count = tof_count + g1 * (g1-1) / 2
                            if mode & 2:
                                tof_count = tof_count + g2 * (g2-1) / 2

                            tof_count = int(tof_count)

                            log_verbose(f"tof_count = {tof_count}")
                            log_verbose(f"unassigned_count = {unassigned_count}")

                            ii = (idx+tof_count*2)

                            new_assignments = []

                            for i in range(0, unassigned_count):
                                if ii + 2 > len(payload):
                                    raise ValueError("New assignments data incomplete")
                                id = struct.unpack('<H', bytes(payload[ii:(ii+2)]))[0]
                                ii = ii + 2
                                new_assignments.append(id)

                                assignments[2][g3-unassigned_count+i] = id

                            log_verbose(f"Updated assignments: {assignments}")

                            results = parse_final(assignments, bytes(payload[idx:]), mode)

                            print_matrix(assignments, results)
                            print_list(results)

                    else:
                        # not a start of packet, needs re-aligning
                        log_verbose(f'Realigning: thrash {hex(s[0])}: {chr((s[0])) if 32 <= s[0] <= 126 else "?"}')
                        s = s[1:]
                        
                except Exception as e:
                    if str(e) == "RESET_REQUIRED":
                        reset(ser)
                        ser.reset_input_buffer()
                        s = []
                        assignments = []
                        continue
                    else:
                        if handle_parsing_error(f"Packet processing: {str(e)}"):
                            reset(ser)
                            ser.reset_input_buffer()
                            s = []
                            assignments = []
                            continue

except KeyboardInterrupt:
    log_start("\nShutting down...")
    log_verbose("Keyboard interrupt received, cleaning up...")
    if mqtt_client:
        log_verbose("Stopping MQTT client loop...")
        mqtt_client.loop_stop()
        log_verbose("Disconnecting from MQTT broker...")
        mqtt_client.disconnect()
    log_verbose("Disconnecting from serial port...")
    disconnect(ser)
    log_verbose("Cleanup complete, exiting...")
    sys.exit(0)
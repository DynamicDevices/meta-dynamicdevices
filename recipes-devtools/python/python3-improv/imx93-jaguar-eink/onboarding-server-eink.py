#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Custom Improv onboarding server for imx93-jaguar-eink board
# Based on onboarding-server.py but with board-specific customizations
#

from improv import *
from bless import (  # type: ignore
    BlessServer,
    BlessGATTCharacteristic,
    GATTCharacteristicProperties,
    GATTAttributePermissions
)
from bless.backends.bluezdbus.server import BlessServerBlueZDBus
from typing import Any, Dict, Union, Optional
import sys
import threading
import asyncio
import logging
import uuid
import nmcli
import os
import re
import subprocess

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(name=__name__)

# NOTE: Some systems require different synchronization methods.
trigger: Union[asyncio.Event, threading.Event]
if sys.platform in ["darwin", "win32"]:
    trigger = threading.Event()
else:
    trigger = asyncio.Event()

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(name=__name__)


def build_gatt():
    gatt: Dict = {
        ImprovUUID.SERVICE_UUID.value: {
            ImprovUUID.STATUS_UUID.value: {
                "Properties": (GATTCharacteristicProperties.read |
                               GATTCharacteristicProperties.notify),
                "Permissions": (GATTAttributePermissions.readable |
                                GATTAttributePermissions.writeable)
            },
            ImprovUUID.ERROR_UUID.value: {
                "Properties": (GATTCharacteristicProperties.read |
                               GATTCharacteristicProperties.notify),
                "Permissions": (GATTAttributePermissions.readable |
                                GATTAttributePermissions.writeable)
            },
            ImprovUUID.RPC_COMMAND_UUID.value: {
                "Properties": (GATTCharacteristicProperties.read |
                               GATTCharacteristicProperties.write |
                               GATTCharacteristicProperties.write_without_response),
                "Permissions": (GATTAttributePermissions.readable |
                                GATTAttributePermissions.writeable)
            },
            ImprovUUID.RPC_RESULT_UUID.value: {
                "Properties": (GATTCharacteristicProperties.read |
                               GATTCharacteristicProperties.notify),
                "Permissions": (GATTAttributePermissions.readable)
            },
            ImprovUUID.CAPABILITIES_UUID.value: {
                "Properties": (GATTCharacteristicProperties.read),
                "Permissions": (GATTAttributePermissions.readable)
            },
        }
    }
    return gatt

"""
 Names longer than 10 characters will result in bless
 only advertising the name without the UUIDs on macOS,
 leading to a break with the Improv spec:

 Bluetooth LE Advertisement
The device MUST advertise the Service UUID.
"""

def get_board_id():
    """Get unique board ID from SOC serial number.
    
    Reads the SOC serial number from /sys/devices/soc0/serial_number
    and extracts the last 4 characters to create a unique board identifier.
    
    Returns:
        str: Board ID in format "XXXX" (4 hex characters), or "0000" if unavailable
    """
    try:
        # Read SOC serial number (32-character hex string)
        soc_serial_path = "/sys/devices/soc0/serial_number"
        if os.path.exists(soc_serial_path):
            with open(soc_serial_path, 'r') as f:
                serial = f.read().strip()
                # Extract last 4 characters (most unique portion)
                # Remove any non-hex characters and take last 4
                serial_clean = re.sub(r'[^0-9a-fA-F]', '', serial)
                if len(serial_clean) >= 4:
                    board_id = serial_clean[-4:].upper()  # Last 4 chars, uppercase
                    logger.info(f"Board ID from SOC serial: {board_id}")
                    return board_id
        logger.warning("SOC serial number not found, using default board ID")
    except Exception as e:
        logger.error(f"Error reading board ID: {e}")
    
    # Fallback to default if unavailable
    return "0000"

# Board-specific configuration for imx93-jaguar-eink
# Can be overridden via environment variables
SERVER_HOST = os.getenv("IMPROV_SERVER_HOST", "api.co.uk")
# Generate unique service name from board ID: "eink-XXXX" where XXXX is last 4 chars of SOC serial
BOARD_ID = get_board_id()
DEFAULT_SERVICE_NAME = f"eink-{BOARD_ID}"
SERVICE_NAME = os.getenv("IMPROV_SERVICE_NAME", DEFAULT_SERVICE_NAME)
CON_NAME = os.getenv("IMPROV_CONNECTION_NAME", "improv-eink")
INTERFACE = os.getenv("IMPROV_WIFI_INTERFACE", "wlan0")  # imx93-jaguar-eink uses wlan0
TIMEOUT = int(os.getenv("IMPROV_CONNECTION_TIMEOUT", "10000"))

# Use new_event_loop() or get_event_loop() depending on Python version
# get_event_loop() is deprecated in Python 3.10+ but still works
try:
    loop = asyncio.get_running_loop()
except RuntimeError:
    # No running loop, create new one
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
server = BlessServer(name=SERVICE_NAME, loop=loop)

def wifi_connect(ssid: str, passwd: str) -> Optional[list[str]]:
    logger.warning(
        f"Creating Improv WiFi connection for '{ssid.decode('utf-8')}' with password: '{passwd.decode('utf-8')}'")

    try:
      nmcli.connection.delete(f"{CON_NAME}")
    except:
      print(f'No connection {CON_NAME} to remove')

    try:
      # Create WiFi connection with improved settings for boot-time reliability:
      # - autoconnect-priority 20 (highest priority - ensures wifi-connect.service selects this connection)
      #   Higher than GrosnyIoT (10) so Improv-configured networks are preferred
      # - dhcp-timeout 60 (60 seconds for DHCP, longer than default 45)
      # - autoconnect-retries -1 (retry connection indefinitely - never give up)
      # - auth-retries -1 (retry authentication indefinitely - never give up)
      # ⚠️  CRITICAL: wifi-sec.psk-flags:'0' is REQUIRED for the NetworkManager patch
      # (0001-wifi-dont-clear-secrets-if-stored-in-keyfile.patch) to work correctly.
      # Without this, the patch will not activate and connections may fail permanently
      # after 4-way handshake failures.
      # See: meta-dynamicdevices-distro/recipes-connectivity/networkmanager/networkmanager/README_PATCH_REQUIREMENTS.md
      nmcli.connection.add('wifi', {
          'ssid': ssid.decode('utf-8'),
          'wifi-sec.key-mgmt': 'wpa-psk',
          'wifi-sec.psk': passwd.decode('utf-8'),
          'wifi-sec.psk-flags': '0',  # REQUIRED: Store PSK in file, not agent-only (patch requirement)
          'connection.autoconnect': 'yes',
          'connection.autoconnect-priority': '20',
          'connection.autoconnect-retries': '-1',  # Retry connection indefinitely (-1 = unlimited)
          'connection.auth-retries': '-1',  # Retry authentication indefinitely (-1 = unlimited)
          'connection.permissions': '',  # Allow system-wide use
          'ipv4.dhcp-timeout': '60'
      }, f"{INTERFACE}", f"{CON_NAME}", True)
      logger.info(f"Successfully created WiFi connection {CON_NAME}")
      
    except Exception as e:
      logger.error(f"Failed to create WiFi connection {CON_NAME}: {e}", exc_info=True)
      print(f'Could not add new connection {CON_NAME}: {e}')
      return None
    
    # NetworkManager automatically saves connections when created/modified
    # In NetworkManager 1.46.0+, connections are saved automatically to
    # /etc/NetworkManager/system-connections/ when created with nmcli.connection.add()
    # The psk-flags=0 setting is persisted automatically.
    # Use 'reload' to ensure NetworkManager picks up the connection immediately
    try:
        subprocess.run(['nmcli', 'connection', 'reload'], 
                      check=True, capture_output=True, timeout=5)
        logger.debug(f"Reloaded NetworkManager connections")
    except subprocess.CalledProcessError as e:
        logger.debug(f"Could not reload NetworkManager connections (exit code {e.returncode}): {e.stderr.decode() if e.stderr else 'unknown error'}")
        # Non-critical - connection is already saved automatically
    except subprocess.TimeoutExpired as e:
        logger.debug(f"Timeout reloading NetworkManager connections: {e}")
        # Non-critical - connection is already saved automatically
    except FileNotFoundError:
        logger.debug(f"nmcli command not found - cannot reload connections")
        # Non-critical - connection is already saved automatically
    except Exception as e:
        logger.debug(f"Unexpected error reloading connections: {e}")
        # Non-critical - connection is already saved automatically
    
    # Verify connection file exists and has correct settings
    connection_file = f"/etc/NetworkManager/system-connections/{CON_NAME}.nmconnection"
    try:
        if os.path.exists(connection_file):
            logger.debug(f"Connection file exists: {connection_file}")
            # Read file to verify psk-flags=0 is set
            with open(connection_file, 'r') as f:
                content = f.read()
                if 'psk-flags=0' in content or 'psk-flags=0\n' in content:
                    logger.debug(f"Verified psk-flags=0 in connection file")
                else:
                    logger.warning(f"psk-flags=0 not found in connection file - connection may not work correctly")
        else:
            logger.warning(f"Connection file not found at {connection_file} - connection may not persist")
    except Exception as e:
        logger.debug(f"Could not verify connection file: {e}")
        # Non-critical - just for verification

    try:
      nmcli.connection.up(f"{CON_NAME}", TIMEOUT)
    except:
      print(f'Error bringing connection {CON_NAME} up')
      return None

    dev_details = nmcli.device.show(f"{INTERFACE}")
    if 'IP4.ADDRESS[1]' in dev_details.keys():
      dev_addr = dev_details['IP4.ADDRESS[1]']
      ip_addr = dev_addr.split('/')[0]
    else:
      print('Error connecting')
      return None

    token = uuid.uuid4()
    server = f"https://{SERVER_HOST}?ip_address={ip_addr}&token={token}"
    return [server]

improv_server = ImprovProtocol(wifi_connect_callback=wifi_connect)

def read_request(
        characteristic: BlessGATTCharacteristic,
        **kwargs
) -> bytearray:
    try:
        improv_char = ImprovUUID(characteristic.uuid)
        logger.info(f"Reading {improv_char} : {characteristic}")
    except Exception:
        logger.info(f"Reading {characteristic.uuid}")
        pass
    if characteristic.service_uuid == ImprovUUID.SERVICE_UUID.value:
        return improv_server.handle_read(characteristic.uuid)
    return characteristic.value


def write_request(
        characteristic: BlessGATTCharacteristic,
        value: bytearray,
        **kwargs
):

    if characteristic.service_uuid == ImprovUUID.SERVICE_UUID.value:
        (target_uuid, target_values) = improv_server.handle_write(
            characteristic.uuid, value)
        if target_uuid != None and target_values != None:
            for value in target_values:
                logger.debug(
                    f"Setting {ImprovUUID(target_uuid)} to {value}")
                server.get_characteristic(
                    target_uuid,
                ).value = value
                success = server.update_value(
                    ImprovUUID.SERVICE_UUID.value,
                    target_uuid
                )
                if not success:
                    logger.warning(
                        f"Updating characteristic return status={success}")

async def run(loop):

    server.read_request_func = read_request
    server.write_request_func = write_request

    if isinstance(server, BlessServerBlueZDBus):
        await server.setup_task
        interface = server.adapter.get_interface('org.bluez.Adapter1')
        powered = await interface.get_powered()
        if not powered:
            logger.info("bluetooth device is not powered, powering now!")
            await interface.set_powered(True)

    await server.add_gatt(build_gatt())
    await server.start()

    logger.info("Server started")

    try:
        trigger.clear()
        if trigger.__module__ == "threading":
            trigger.wait()
        else:
            await trigger.wait()
    except KeyboardInterrupt:
        logger.debug("Shutting Down")
        pass
    await server.stop()

# Actually start the server
try:
    loop.run_until_complete(run(loop))
except KeyboardInterrupt:
    logger.debug("Shutting Down")
    trigger.set()
    pass


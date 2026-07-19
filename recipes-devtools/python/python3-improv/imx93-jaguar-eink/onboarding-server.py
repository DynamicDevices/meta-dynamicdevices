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
import json
import socket
import struct
import fcntl

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(name=__name__)

# Version of this onboarding server; exposed as DIS Software Revision (0x2A28).
__version__ = "1.1.0"

# --- Device Information Service (SIG standard, 0x180A) ------------------------
# Full 128-bit forms so bless/BlueZ resolves characteristics by UUID.
DIS_SERVICE_UUID = "0000180a-0000-1000-8000-00805f9b34fb"
DIS_MANUFACTURER_UUID = "00002a29-0000-1000-8000-00805f9b34fb"
DIS_MODEL_UUID = "00002a24-0000-1000-8000-00805f9b34fb"
DIS_SERIAL_UUID = "00002a25-0000-1000-8000-00805f9b34fb"
DIS_FW_REV_UUID = "00002a26-0000-1000-8000-00805f9b34fb"
DIS_HW_REV_UUID = "00002a27-0000-1000-8000-00805f9b34fb"
DIS_SW_REV_UUID = "00002a28-0000-1000-8000-00805f9b34fb"

# --- Dynamic Devices vendor Network Status service ---------------------------
# No SIG standard exists for live IP/SSID/link state, so use a vendor service.
# Base UUID generated once and reused across the board range: service ...-0001,
# network-status characteristic ...-0002 (room for future characteristics).
NET_STATUS_SERVICE_UUID = "e5f10001-9d3a-4b7c-8a21-6f2c9b4d7e10"
NET_STATUS_CHAR_UUID = "e5f10002-9d3a-4b7c-8a21-6f2c9b4d7e10"

trigger: Union[asyncio.Event, threading.Event]
if sys.platform in ["darwin", "win32"]:
    trigger = threading.Event()
else:
    trigger = asyncio.Event()


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

    # Device Information Service (identity), read-only. Added AFTER the Improv
    # service so bless advertises only services[0] (Improv); DIS and the vendor
    # service are discovered post-connect but are not advertised (keeping the
    # legacy advertisement within the 31-byte budget).
    def _ro():
        return {
            "Properties": GATTCharacteristicProperties.read,
            "Permissions": GATTAttributePermissions.readable,
        }

    gatt[DIS_SERVICE_UUID] = {
        DIS_MANUFACTURER_UUID: _ro(),
        DIS_MODEL_UUID: _ro(),
        DIS_SERIAL_UUID: _ro(),
        DIS_FW_REV_UUID: _ro(),
        DIS_HW_REV_UUID: _ro(),
        DIS_SW_REV_UUID: _ro(),
    }

    # Vendor Network Status service, read + notify, carrying a JSON snapshot.
    gatt[NET_STATUS_SERVICE_UUID] = {
        NET_STATUS_CHAR_UUID: {
            "Properties": (GATTCharacteristicProperties.read |
                           GATTCharacteristicProperties.notify),
            "Permissions": GATTAttributePermissions.readable,
        },
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
    """Get unique board ID from SOC serial number."""
    try:
        soc_serial_path = "/sys/devices/soc0/serial_number"
        if os.path.exists(soc_serial_path):
            with open(soc_serial_path, 'r') as f:
                serial = f.read().strip()
                serial_clean = re.sub(r'[^0-9a-fA-F]', '', serial)
                if len(serial_clean) >= 4:
                    board_id = serial_clean[-4:].upper()
                    logger.info(f"Board ID from SOC serial: {board_id}")
                    return board_id
        logger.warning("SOC serial number not found, using default board ID")
    except Exception as e:
        logger.error(f"Error reading board ID: {e}")
    return "0000"


def get_soc_serial():
    """Get the full SoC unique serial (hex, uppercased) for DIS Serial Number."""
    try:
        soc_serial_path = "/sys/devices/soc0/serial_number"
        if os.path.exists(soc_serial_path):
            with open(soc_serial_path, 'r') as f:
                serial = re.sub(r'[^0-9a-fA-F]', '', f.read().strip()).upper()
                if serial:
                    return serial
    except Exception as e:
        logger.error(f"Error reading SoC serial: {e}")
    return "UNKNOWN"


def get_board_model():
    """Human-readable board model from the device tree, else MACHINE/env."""
    try:
        dt_model = "/proc/device-tree/model"
        if os.path.exists(dt_model):
            with open(dt_model, 'rb') as f:
                model = f.read().decode('utf-8', 'replace').replace('\x00', '').strip()
                if model:
                    return model
    except Exception as e:
        logger.debug(f"Error reading board model: {e}")
    return os.getenv("MACHINE", "imx93-jaguar-eink")


def get_fw_revision():
    """Firmware/OS revision parsed from /etc/os-release."""
    try:
        data = {}
        with open("/etc/os-release") as f:
            for line in f:
                if "=" in line:
                    k, v = line.rstrip("\n").split("=", 1)
                    data[k] = v.strip().strip('"')
        for key in ("IMAGE_VERSION", "BUILD_ID", "VERSION_ID", "VERSION"):
            if data.get(key):
                return data[key]
        if data.get("PRETTY_NAME"):
            return data["PRETTY_NAME"]
    except Exception as e:
        logger.debug(f"Error reading firmware revision: {e}")
    return "unknown"


def get_hw_revision():
    """Hardware revision. No standard source on this SoC; overridable via env."""
    return "unknown"

# Board-specific configuration for imx93-jaguar-eink (overridable via environment)
SERVER_HOST = os.getenv("IMPROV_SERVER_HOST", "api.co.uk")
BOARD_ID = get_board_id()
DEFAULT_SERVICE_NAME = f"eink-{BOARD_ID}"
SERVICE_NAME = os.getenv("IMPROV_SERVICE_NAME", DEFAULT_SERVICE_NAME)
CON_NAME = os.getenv("IMPROV_CONNECTION_NAME", "improv-eink")
INTERFACE = os.getenv("IMPROV_WIFI_INTERFACE", "wlan0")
TIMEOUT = int(os.getenv("IMPROV_CONNECTION_TIMEOUT", "10000"))

# Device Information Service values (auto-detected, overridable via environment
# for multi-board reuse).
SOC_SERIAL = get_soc_serial()
MANUFACTURER = os.getenv("IMPROV_MANUFACTURER", "Dynamic Devices Ltd")
MODEL = os.getenv("IMPROV_MODEL", get_board_model())
FW_REV = os.getenv("IMPROV_FW_REV", get_fw_revision())
HW_REV = os.getenv("IMPROV_HW_REV", get_hw_revision())

try:
    loop = asyncio.get_running_loop()
except RuntimeError:
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
server = BlessServer(name=SERVICE_NAME, loop=loop)

# --- Network status (custom vendor characteristic) ---------------------------
# Cached JSON snapshot served on BLE reads; recomputed off the BLE event loop so
# reads never block on nmcli.
_net_status_json_bytes = bytearray(
    json.dumps({"v": 1, "state": "disconnected", "iface": INTERFACE},
               separators=(",", ":")).encode("utf-8"))

# Set to ask net_status_loop to refresh immediately (e.g. just after a
# successful provision) without running the blocking nmcli work on the BLE loop.
_net_refresh_event = asyncio.Event()


def get_ipv4(iface):
    """Return the interface IPv4 via ioctl (no subprocess), or None."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            packed = struct.pack('256s', iface[:15].encode('utf-8'))
            addr = fcntl.ioctl(s.fileno(), 0x8915, packed)[20:24]  # SIOCGIFADDR
            return socket.inet_ntoa(addr)
        finally:
            s.close()
    except Exception:
        return None


def get_ssid(iface):
    """Best-effort current SSID via nmcli (called off the BLE read path)."""
    # 1) Active AP from the scan list.
    try:
        out = subprocess.run(["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"],
                             capture_output=True, timeout=4, text=True)
        for line in out.stdout.splitlines():
            if line.startswith("yes:"):
                ssid = line.split(":", 1)[1].strip()
                if ssid:
                    return ssid
    except Exception:
        pass
    # 2) Fall back to the SSID stored on the interface's active connection
    #    (reliable right after provisioning, before the scan cache updates).
    try:
        conn = (nmcli.device.show(iface) or {}).get("GENERAL.CONNECTION")
        if conn and conn not in ("--", ""):
            out = subprocess.run(
                ["nmcli", "-s", "-g", "802-11-wireless.ssid",
                 "connection", "show", conn],
                capture_output=True, timeout=4, text=True)
            ssid = out.stdout.strip()
            if ssid:
                return ssid
    except Exception:
        pass
    return None


def compute_net_status():
    """Build the current network-status dict (blocking; call off the BLE loop)."""
    status = {"v": 1, "state": "disconnected", "iface": INTERFACE}
    # Derive link state from NetworkManager's numeric device-state code
    # (100=connected, 40..99=connecting/configuring, else disconnected). String
    # matching is unsafe here because "disconnected" contains "connected".
    #
    # NM is authoritative: a lingering interface IP must NOT upgrade a
    # disconnected/failed device to "connected". If we cannot read NM's state we
    # stay "disconnected" (conservative) rather than trusting a possibly-stale IP.
    code = 0
    try:
        d = nmcli.device.show(INTERFACE)
        m = re.match(r"\s*(\d+)", d.get("GENERAL.STATE") or "")
        code = int(m.group(1)) if m else 0
    except Exception as e:
        logger.debug(f"nmcli device state read failed: {e}")
        code = 0
    ip = get_ipv4(INTERFACE)
    if code >= 100:
        status["state"] = "connected" if ip else "connecting"
    elif code >= 40:
        status["state"] = "connecting"
    else:
        status["state"] = "disconnected"
    # Only surface IP/SSID/RSSI when actually connected; a stale IP on a
    # down interface would otherwise be misreported as a live connection.
    if status["state"] == "connected":
        if ip:
            status["ipv4"] = ip
        ssid = get_ssid(INTERFACE)
        if ssid:
            status["ssid"] = ssid
        try:
            with open("/proc/net/wireless") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith(INTERFACE + ":"):
                        parts = line.split()
                        if len(parts) > 3:
                            rssi = int(float(parts[3].rstrip(".")))
                            if -120 <= rssi <= 0:
                                status["rssi"] = rssi
        except Exception:
            pass
    return status


def _publish_net_status(status_dict, notify=True):
    """Update the cached JSON + characteristic value; notify on change."""
    global _net_status_json_bytes
    data = json.dumps(status_dict, separators=(",", ":")).encode("utf-8")
    changed = bytes(data) != bytes(_net_status_json_bytes)
    _net_status_json_bytes = bytearray(data)
    try:
        ch = server.get_characteristic(NET_STATUS_CHAR_UUID)
        if ch is not None:
            ch.value = bytearray(data)
            if notify and changed:
                server.update_value(NET_STATUS_SERVICE_UUID, NET_STATUS_CHAR_UUID)
    except Exception as e:
        logger.debug(f"net status publish failed: {e}")
    return changed


def _set_dis_values():
    """Populate the static Device Information Service characteristic values."""
    values = {
        DIS_MANUFACTURER_UUID: MANUFACTURER,
        DIS_MODEL_UUID: MODEL,
        DIS_SERIAL_UUID: SOC_SERIAL,
        DIS_FW_REV_UUID: FW_REV,
        DIS_HW_REV_UUID: HW_REV,
        DIS_SW_REV_UUID: __version__,
    }
    for uuid_, val in values.items():
        try:
            ch = server.get_characteristic(uuid_)
            if ch is not None:
                ch.value = bytearray((val or "").encode("utf-8"))
        except Exception as e:
            logger.debug(f"set DIS {uuid_} failed: {e}")


async def net_status_loop(loop):
    """Periodically refresh network status off the BLE event loop.

    The blocking nmcli work runs in an executor so the asyncio/BLE loop stays
    responsive; publishing (which touches the BlueZ characteristic) happens back
    on the loop thread. Wakes early when `_net_refresh_event` is set.
    """
    while True:
        try:
            status = await loop.run_in_executor(None, compute_net_status)
            _publish_net_status(status)
        except asyncio.CancelledError:
            raise
        except Exception as e:
            logger.debug(f"net status loop error: {e}")
        try:
            await asyncio.wait_for(_net_refresh_event.wait(), timeout=5)
        except asyncio.TimeoutError:
            pass
        finally:
            _net_refresh_event.clear()


def wifi_connect(ssid: str, passwd: str) -> Optional[list[str]]:
    logger.warning(
        f"Creating Improv WiFi connection for '{ssid.decode('utf-8')}' with password: '{passwd.decode('utf-8')}'")

    try:
      nmcli.connection.delete(f"{CON_NAME}")
    except:
      print(f'No connection {CON_NAME} to remove')

    try:
      nmcli.connection.add('wifi', {
          'ssid': ssid.decode('utf-8'),
          'wifi-sec.key-mgmt': 'wpa-psk',
          'wifi-sec.psk': passwd.decode('utf-8'),
          'wifi-sec.psk-flags': '0',
          'connection.autoconnect': 'yes',
          'connection.autoconnect-priority': '20',
          'connection.autoconnect-retries': '-1',
          'connection.auth-retries': '-1',
          'connection.permissions': '',  # Allow system-wide use
          'ipv4.dhcp-timeout': '60'
      }, f"{INTERFACE}", f"{CON_NAME}", True)
      logger.info(f"Successfully created WiFi connection {CON_NAME}")
    except Exception as e:
      logger.error(f"Failed to create WiFi connection {CON_NAME}: {e}", exc_info=True)
      print(f'Could not add new connection {CON_NAME}: {e}')
      return None

    connection_file = f"/etc/NetworkManager/system-connections/{CON_NAME}.nmconnection"
    try:
        if os.path.exists(connection_file):
            with open(connection_file, 'r') as f:
                content = f.read()
            if 'psk-flags=0' not in content and 'psk-flags=0\n' not in content:
                pattern = r'(\[wifi-security\]\n(?:[^\[]*\n)*?psk=[^\n]+\n)'
                replacement = r'\1psk-flags=0\n'
                new_content = re.sub(pattern, replacement, content)
                if new_content == content:
                    pattern = r'(\[wifi-security\]\n)'
                    replacement = r'\1psk-flags=0\n'
                    new_content = re.sub(pattern, replacement, content)
                if new_content != content:
                    with open(connection_file, 'w') as f:
                        f.write(new_content)
                    logger.info(f"Added psk-flags=0 to connection file {connection_file}")
        else:
            logger.warning(f"Connection file not found at {connection_file}")
    except PermissionError:
        try:
            subprocess.run(['nmcli', 'connection', 'modify', f"{CON_NAME}",
                           '802-11-wireless-security.psk-flags', '0'],
                          check=True, capture_output=True, timeout=5)
        except Exception:
            pass
    except Exception as e:
        logger.warning(f"Unexpected error adding psk-flags=0 to file: {e}", exc_info=True)

    try:
        subprocess.run(['nmcli', 'connection', 'reload'], check=True, capture_output=True, timeout=5)
    except Exception:
        pass

    connection_file = f"/etc/NetworkManager/system-connections/{CON_NAME}.nmconnection"
    try:
        if os.path.exists(connection_file):
            with open(connection_file, 'r') as f:
                content = f.read()
                if 'psk-flags=0' in content or 'psk-flags=0\n' in content:
                    logger.debug(f"Verified psk-flags=0 in connection file")
    except Exception as e:
        logger.debug(f"Could not verify connection file: {e}")

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

    # Ask the status loop to refresh immediately so the connected state/SSID/IP
    # notify promptly. We deliberately do NOT call compute_net_status() here:
    # this runs on the BLE event loop, and nmcli subprocesses would stall Improv
    # read/write handling right after provisioning.
    try:
        _net_refresh_event.set()
    except Exception as e:
        logger.debug(f"net status refresh request failed: {e}")

    token = uuid.uuid4()
    server = f"https://{SERVER_HOST}?ip_address={ip_addr}&token={token}"
    return [server]

# Improv chunks its RPC response into <= max_response_bytes packets. The library
# default (100) is *below* our Wi-Fi-success redirect URL length (~117 B: the
# active-esl-onboard.active-esl.workers.dev host + a UUID token), which trips a
# pyImprov bug: it emits a spurious zero-length WIFI_SETTINGS packet *before* the
# packet carrying the URL. Clients that complete on the first result then never
# see the token ("connected to Wi-Fi but no claim token"). Raise the threshold so
# the URL is returned in a single packet (~121 B, well within the ~185 B BLE MTU
# the app negotiates).
improv_server = ImprovProtocol(wifi_connect_callback=wifi_connect,
                               max_response_bytes=200)

def read_request(characteristic: BlessGATTCharacteristic, **kwargs) -> bytearray:
    try:
        improv_char = ImprovUUID(characteristic.uuid)
        logger.info(f"Reading {improv_char} : {characteristic}")
    except Exception:
        logger.info(f"Reading {characteristic.uuid}")
    if str(characteristic.uuid).lower() == NET_STATUS_CHAR_UUID:
        return bytearray(_net_status_json_bytes)
    if characteristic.service_uuid == ImprovUUID.SERVICE_UUID.value:
        return improv_server.handle_read(characteristic.uuid)
    return characteristic.value


def write_request(characteristic: BlessGATTCharacteristic, value: bytearray, **kwargs):
    if characteristic.service_uuid == ImprovUUID.SERVICE_UUID.value:
        (target_uuid, target_values) = improv_server.handle_write(characteristic.uuid, value)
        if target_uuid != None and target_values != None:
            for value in target_values:
                logger.debug(f"Setting {ImprovUUID(target_uuid)} to {value}")
                server.get_characteristic(target_uuid).value = value
                success = server.update_value(ImprovUUID.SERVICE_UUID.value, target_uuid)
                if not success:
                    logger.warning(f"Updating characteristic return status={success}")

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

    # Populate the static Device Information Service values.
    _set_dis_values()
    # Seed network status once (off the BLE loop so nmcli doesn't stall startup),
    # then refresh periodically / on demand.
    try:
        status = await loop.run_in_executor(None, compute_net_status)
        _publish_net_status(status, notify=False)
    except Exception as e:
        logger.debug(f"initial net status failed: {e}")
    net_task = loop.create_task(net_status_loop(loop))

    try:
        trigger.clear()
        if trigger.__module__ == "threading":
            trigger.wait()
        else:
            await trigger.wait()
    except KeyboardInterrupt:
        logger.debug("Shutting Down")
    finally:
        net_task.cancel()
    await server.stop()

try:
    loop.run_until_complete(run(loop))
except KeyboardInterrupt:
    logger.debug("Shutting Down")
    trigger.set()

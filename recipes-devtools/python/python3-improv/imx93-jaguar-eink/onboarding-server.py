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
import time

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

# Board-specific configuration for imx93-jaguar-eink (overridable via environment).
# Default is the live Active-ESL onboarding backend; improv.service also sets this
# via IMPROV_SERVER_HOST, but the default must be a real host so the server still
# points somewhere valid if the env var is ever missing.
SERVER_HOST = os.getenv(
    "IMPROV_SERVER_HOST", "active-esl-onboard.active-esl.workers.dev"
)
BOARD_ID = get_board_id()
DEFAULT_SERVICE_NAME = f"eink-{BOARD_ID}"
SERVICE_NAME = os.getenv("IMPROV_SERVICE_NAME", DEFAULT_SERVICE_NAME)
CON_NAME = os.getenv("IMPROV_CONNECTION_NAME", "improv-eink")
INTERFACE = os.getenv("IMPROV_WIFI_INTERFACE", "wlan0")
TIMEOUT = int(os.getenv("IMPROV_CONNECTION_TIMEOUT", "10000"))
# How often the advertising watchdog re-checks that BlueZ is still advertising
# and re-registers it if not. Kept short so a dropped advert self-heals within
# seconds — onboarding must never depend on a manual service restart.
ADVERT_WATCHDOG_SECS = int(os.getenv("IMPROV_ADVERT_WATCHDOG_SECS", "15"))
# Hard timeout on each BlueZ D-Bus call the watchdog makes, so a wedged BLE
# stack can never freeze the watchdog loop itself.
ADVERT_DBUS_TIMEOUT = float(os.getenv("IMPROV_ADVERT_DBUS_TIMEOUT", "5"))
# Consecutive watchdog failures (can't query state, or can't re-register) after
# which we treat the BLE stack as unrecoverable and exit so systemd restarts us
# (Restart=always) — a clean re-init reliably restores advertising.
ADVERT_MAX_FAILURES = int(os.getenv("IMPROV_ADVERT_MAX_FAILURES", "3"))
# How often we proactively BOUNCE (unregister + re-register) the advertisement
# even while BlueZ reports it as active. This is the backstop for the "ghost
# advertising" state: BlueZ reports ActiveInstances>=1 but nothing is actually
# on-air, so is_advertising() looks healthy and the drop-detection above never
# fires. Observed after a failed/aborted BLE connect and around a fresh boot,
# with Wi-Fi OFF (so not coexistence) — the board silently becomes
# un-onboardable until a manual restart. Since ActiveInstances cannot tell us
# whether the advert is truly radiating, we periodically re-assert it; kept
# short so onboarding recovers within ~a minute without a restart. A bounce is
# a sub-second re-register gap and is skipped whenever a central is mid-session.
ADVERT_BOUNCE_SECS = int(os.getenv("IMPROV_ADVERT_BOUNCE_SECS", "60"))

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
    json.dumps({"v": 1,
                "net": {"bearer": "wifi", "state": "disconnected",
                        "iface": INTERFACE},
                "state": "disconnected", "iface": INTERFACE},
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


# --- Device-Status superset (BLE-BOARD-PROFILE.md §5 / §5.1) ------------------
# The vendor characteristic now carries the full Device-Status document: the
# mandatory `net` block plus optional `time` and `sec` blocks. The legacy flat
# {state,ssid,ipv4,rssi,iface} keys are mirrored at the top level for one release
# so older app builds keep working; the app prefers the nested `net` block.
_SEC_STATUS = None


def compute_time_status():
    """Wall-clock/time-sync status (`time` block).

    `synced` comes from systemd-timesyncd's stamp file (root-free, no
    subprocess). The PCF2131 RTC is unreliable on this board, so we report
    `ntp` when synced and `none` otherwise rather than trusting the RTC.
    """
    synced = os.path.exists("/run/systemd/timesync/synchronized")
    now = time.time()
    return {
        "epoch": int(now),
        "iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now)),
        "source": "ntp" if synced else "none",
        "synced": synced,
    }


def _read_secure_boot():
    """i.MX93 secure-boot posture. Returns 'open' | 'closed' | 'unknown'.

    The authoritative source is the EdgeLock Enclave (ELE) "get info"
    lifecycle field (OEM_OPEN vs OEM_CLOSED / FIELD_RETURN). This kernel,
    however, exposes no ELE MU char device (`/dev/ele_mu` absent) and no
    lifecycle nvmem cell — the lifecycle lives behind OP-TEE/secure world —
    so it cannot be read from Linux userspace without a dedicated OP-TEE TA.
    That ELE-attested query remains a tracked follow-up (roadmap P0-1/P2-1,
    BLE-BOARD-PROFILE.md §10) and needs secure-world plumbing.

    As the best available userspace signal we read U-Boot's `sec_boot`
    environment flag, which the NXP boot script uses to gate authenticated
    boot (`auth_os`): 'yes' => authenticated boot enforced ('closed'),
    'no' => not enforced ('open'). This reflects the *bootloader
    configuration* rather than an ELE-attested hardware lifecycle, and —
    like the whole `sec` block — is self-reported and untrusted until backed
    by attestation (P2-1). A fuse/OCOTP byte heuristic is deliberately
    avoided: the ELE-OCOTP0 shadow has non-zero UID/config words, so
    byte-level guessing would misreport a fused board.
    """
    val = ""
    try:
        # `-n` prints just the value; falls back to parsing `k=v` for older
        # u-boot-fw-utils that lack `-n`.
        out = subprocess.run(["fw_printenv", "-n", "sec_boot"],
                             capture_output=True, timeout=4, text=True)
        if out.returncode == 0:
            val = out.stdout.strip().lower()
        else:
            out = subprocess.run(["fw_printenv", "sec_boot"],
                                 capture_output=True, timeout=4, text=True)
            if out.returncode == 0 and "=" in out.stdout:
                val = out.stdout.strip().split("=", 1)[1].strip().lower()
    except Exception as e:
        logger.debug(f"secure_boot read failed: {e}")
        return "unknown"
    if val in ("yes", "1", "true"):
        return "closed"
    if val in ("no", "0", "false"):
        return "open"
    return "unknown"


def _read_storage_encrypted():
    """True if any dm-crypt mapped device exists (root-free via sysfs)."""
    import glob
    try:
        for p in glob.glob("/sys/block/dm-*/dm/uuid"):
            try:
                with open(p) as f:
                    if f.read().startswith("CRYPT-"):
                        return True
            except Exception:
                pass
    except Exception:
        pass
    return False


def compute_sec_status():
    """Self-reported security posture (`sec` block, §10). Cached: these values
    are effectively static for the process lifetime."""
    global _SEC_STATUS
    if _SEC_STATUS is None:
        _SEC_STATUS = {
            "secure_boot": _read_secure_boot(),
            # i.MX93 on-die EdgeLock Enclave (OP-TEE /dev/tee0 present).
            "secure_element": "ele",
            "storage_encrypted": _read_storage_encrypted(),
            # Improv link is Just Works / unbonded today (roadmap P1-1).
            "bonded": False,
            # No remote attestation yet (roadmap P2-1) — sec is untrusted.
            "attested": False,
        }
    return dict(_SEC_STATUS)


def _read_os_release():
    """Parse /etc/os-release into a dict (root-free, no subprocess)."""
    d = {}
    try:
        with open("/etc/os-release") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                d[k] = v.strip().strip('"')
    except Exception as e:
        logger.debug(f"os-release read failed: {e}")
    return d


def compute_ota_status():
    """Foundries enrollment / OTA posture (`ota` block, §5/§10).

    Local, self-reported signals about whether this board is enrolled to a
    Foundries factory and running the OTA client — surfaced over Improv BLE so
    the app can show, during onboarding, whether the board still needs Foundries
    enrolment (see the app/cloud onboard/offboard feature). Not cached: the
    values flip as the board is registered / the daemon starts.

      - `registered`: /var/sota/sota.toml exists — the config lmp-device-register
        writes and the gate aktualizr-lite.service requires
        (ConditionPathExists). Absent => board is not enrolled to any factory.
      - `factory`/`tag`/`hwid`/`target`/`os_version`: baked into /etc/os-release
        at image build time.
      - `daemon`: aktualizr-lite.service is active (the OTA poller is running).
      - `up_to_date`: left null on the board on purpose — the authoritative
        "is this on the latest factory target" answer comes from the
        cloud->Foundries API, not from a device that may be OFFLINE to the
        device-gateway. Like the rest of the diagnostics, this block is
        self-reported and untrusted until backed by attestation (roadmap P2-1).
    """
    osr = _read_os_release()
    registered = os.path.exists("/var/sota/sota.toml")
    daemon = False
    try:
        out = subprocess.run(["systemctl", "is-active", "aktualizr-lite"],
                             capture_output=True, timeout=4, text=True)
        daemon = out.stdout.strip() == "active"
    except Exception as e:
        logger.debug(f"aktualizr-lite is-active failed: {e}")
    target = osr.get("IMAGE_VERSION") or None
    if target is not None:
        try:
            target = int(target)
        except (TypeError, ValueError):
            pass
    return {
        "registered": registered,
        "factory": osr.get("LMP_FACTORY") or None,
        "tag": osr.get("LMP_FACTORY_TAG") or None,
        "hwid": osr.get("LMP_MACHINE") or None,
        "target": target,
        "os_version": osr.get("VERSION_ID") or osr.get("VERSION") or None,
        "daemon": daemon,
        "up_to_date": None,
    }


def build_device_status(net):
    """Compose the Device-Status JSON superset (§5) from the flat network dict.

    Emits the nested `net` block plus `time`/`sec`/`ota`. The legacy top-level
    flat mirror (`state`/`ssid`/`ipv4`/`rssi`/`iface`) is intentionally
    *not* emitted any more: with `ota` included the compact JSON is ~580 bytes
    with the mirror and only ~490 without, and BlueZ/bless caps a single
    characteristic value at 512 bytes (truncating mid-JSON otherwise). The app
    has preferred the nested `net` block since the Device-Status superset
    (meta-dynamicdevices #41) and still falls back to flat for older firmware.
    """
    doc = {"v": 1, "net": {
        "bearer": "wifi",
        "state": net.get("state"),
        "ssid": net.get("ssid"),
        "ipv4": net.get("ipv4"),
        "rssi": net.get("rssi"),
        "iface": net.get("iface"),
    }}
    doc["time"] = compute_time_status()
    doc["sec"] = compute_sec_status()
    doc["ota"] = compute_ota_status()
    return doc


def compute_device_status():
    """Blocking; call off the BLE loop. Full Device-Status superset."""
    return build_device_status(compute_net_status())


# BlueZ/bless characteristic-value ceiling. Truncation mid-JSON is worse than
# omitting a redundant field, so `_publish_net_status` shrinks before send.
_ATT_VALUE_MAX = 512


def _shrink_to_att(doc):
    """Return a compact JSON bytes that fits in one ATT value, or the best-effort
    original. Progressive omits (never invent values): time.iso → ota.os_version
    → ota.hwid. Logs if even the slim form exceeds the ceiling.
    """
    data = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    if len(data) <= _ATT_VALUE_MAX:
        return data
    # 1. Drop time.iso (epoch is enough for the app).
    if "time" in doc and isinstance(doc["time"], dict) and "iso" in doc["time"]:
        slim = dict(doc)
        slim["time"] = {k: v for k, v in doc["time"].items() if k != "iso"}
        data = json.dumps(slim, separators=(",", ":")).encode("utf-8")
        if len(data) <= _ATT_VALUE_MAX:
            logger.info("Device-Status shrunk: dropped time.iso (%d bytes)", len(data))
            return data
        doc = slim
    # 2. Drop ota.os_version / ota.hwid (derivable from factory image / machine).
    if "ota" in doc and isinstance(doc["ota"], dict):
        slim = dict(doc)
        ota = {k: v for k, v in doc["ota"].items() if k not in ("os_version", "hwid")}
        slim["ota"] = ota
        data = json.dumps(slim, separators=(",", ":")).encode("utf-8")
        if len(data) <= _ATT_VALUE_MAX:
            logger.info("Device-Status shrunk: dropped ota.os_version/hwid (%d bytes)",
                        len(data))
            return data
        doc = slim
    logger.warning("Device-Status JSON still %d bytes > ATT max %d; truncating",
                   len(data), _ATT_VALUE_MAX)
    return data[:_ATT_VALUE_MAX]


def _publish_net_status(status_dict, notify=True):
    """Update the cached JSON + characteristic value; notify on change."""
    global _net_status_json_bytes
    data = _shrink_to_att(status_dict)
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
            status = await loop.run_in_executor(None, compute_device_status)
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


def _drop_stale_adverts():
    """Unexport and forget any advertisement objects bless is still tracking.

    Used when BlueZ has already dropped the advertisement (ActiveInstances==0):
    bless's stale objects would otherwise leak D-Bus objects and keep pushing the
    advertisement instance index upward on repeated recoveries.

    This is deliberately NOT wrapped in a timeout like the stop/start_advertising
    calls: ``bus.unexport`` is purely local, non-blocking bookkeeping. It removes
    the object from dbus-fast's export table and buffers a non-blocking
    ``InterfacesRemoved`` signal — there is no awaited D-Bus round-trip that a
    wedged BlueZ stack could stall on, so there is nothing to time out. It must
    also run on the event-loop thread (the dbus-fast bus is loop-affine), so it
    cannot be offloaded to an executor. Each call is guarded so one bad object
    can never abort the cleanup of the rest.
    """
    app = server.app
    stale = getattr(app, "advertisements", None)
    if not stale:
        return
    for old in list(stale):
        try:
            app.bus.unexport(old.path)
        except Exception as e:
            logger.debug(f"unexport of stale advert {old.path!r} failed: {e!r}")
    stale.clear()


async def _reassert_advert(had_registration: bool):
    """(Re)assert the BLE advertisement so it is actually radiating again.

    had_registration True  -> BlueZ still reports the advert (a bounce): cleanly
                              stop_advertising() first so BlueZ drops the live
                              instance, then start a fresh one.
    had_registration False -> BlueZ already forgot it: drop bless's stale
                              trackers, then start a fresh one.
    """
    app = server.app
    adapter = server.adapter
    if had_registration:
        try:
            await asyncio.wait_for(
                app.stop_advertising(adapter), timeout=ADVERT_DBUS_TIMEOUT)
        except Exception as e:
            logger.warning(
                f"advert bounce: stop_advertising failed ({e!r}); "
                "clearing stale objects instead")
            _drop_stale_adverts()
    else:
        _drop_stale_adverts()
    await asyncio.wait_for(
        app.start_advertising(adapter), timeout=ADVERT_DBUS_TIMEOUT)


async def advertising_watchdog():
    """Keep the Improv BLE advertisement alive AND actually on-air for the whole
    product lifetime.

    Two independent failure modes are handled:

    1. Registration drop — BlueZ forgets the advertisement entirely
       (ActiveInstances==0). bless registers it exactly once (in
       ``server.start()``), so without this it stays gone until a manual restart.
       Seen after ~an hour of uptime, adapter resets, and post-provision
       NetworkManager churn.

    2. On-air stall ("ghost advertising") — BlueZ still reports
       ActiveInstances>=1 but nothing is radiating, so ``is_advertising()`` looks
       healthy and case 1 never fires. Reproduced after a failed/aborted BLE
       connect and around a fresh boot, with Wi-Fi OFF (so not coexistence): the
       board silently becomes un-onboardable until a manual restart. Because
       ActiveInstances cannot tell us whether the advert is truly on-air, we
       cannot *detect* this directly — instead we periodically BOUNCE (re-assert)
       the advertisement every ``ADVERT_BOUNCE_SECS`` so any stall self-heals
       within about a minute.

    Both re-assertions are skipped while a central is mid-session (a subscribed
    characteristic) so we never disrupt an in-progress onboarding.
    """
    logger.info(
        f"advertising watchdog started (check every {ADVERT_WATCHDOG_SECS}s, "
        f"bounce every {ADVERT_BOUNCE_SECS}s)")
    failures = 0
    last_assert = time.monotonic()
    while True:
        await asyncio.sleep(ADVERT_WATCHDOG_SECS)

        # 1) Query current state, but never let a wedged BLE stack freeze the
        #    loop: bound every D-Bus call with a timeout.
        try:
            connected = await asyncio.wait_for(
                server.is_connected(), timeout=ADVERT_DBUS_TIMEOUT)
            advertising = await asyncio.wait_for(
                server.is_advertising(), timeout=ADVERT_DBUS_TIMEOUT)
        except asyncio.CancelledError:
            raise
        except Exception as e:
            failures += 1
            logger.error(
                f"advertising watchdog: cannot query BLE state ({e!r}); "
                f"failures={failures}/{ADVERT_MAX_FAILURES}")
            if failures >= ADVERT_MAX_FAILURES:
                logger.error("advertising watchdog: BLE stack unresponsive; "
                             "exiting so systemd restarts the service")
                os._exit(1)
            continue

        logger.debug(
            f"advertising watchdog: connected={connected} "
            f"advertising={advertising}")

        # 2) A central is mid-session — never disturb an in-progress onboarding.
        #    Reset the bounce clock so we don't bounce the instant it leaves.
        if connected:
            failures = 0
            last_assert = time.monotonic()
            continue

        now = time.monotonic()
        due_for_bounce = (now - last_assert) >= ADVERT_BOUNCE_SECS

        # 3) Healthy registration and not yet due a bounce — leave it alone.
        if advertising and not due_for_bounce:
            if failures:
                logger.info("advertising watchdog: BLE advertising healthy again")
            failures = 0
            continue

        # 4) Re-assert the advertisement: either it is fully down
        #    (ActiveInstances==0), or it is due a periodic bounce to clear a
        #    possible on-air stall that BlueZ still reports as active.
        reason = ("advertisement is down (ActiveInstances==0)"
                  if not advertising else
                  "periodic bounce (clears on-air stalls BlueZ reports as active)")
        logger.warning(f"re-asserting BLE advertisement: {reason}")
        try:
            await _reassert_advert(had_registration=advertising)
            last_assert = time.monotonic()
            logger.info("BLE advertisement re-asserted by watchdog")
            failures = 0
        except asyncio.CancelledError:
            raise
        except Exception as e:
            failures += 1
            logger.error(
                f"advertising watchdog: re-assert failed ({e!r}); "
                f"failures={failures}/{ADVERT_MAX_FAILURES}")
            if failures >= ADVERT_MAX_FAILURES:
                logger.error("advertising watchdog: cannot restore advertising; "
                             "exiting so systemd restarts the service")
                os._exit(1)


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
    # Start the background tasks FIRST — especially the advertising watchdog,
    # which must run even if the initial network probe below is slow/blocks.
    # (Creating them before the initial seed guarantees the event loop keeps the
    # watchdog alive regardless of how long the seed's executor call takes.)
    net_task = loop.create_task(net_status_loop(loop))
    # Self-healing advertising: onboarding must never rely on a manual restart.
    advert_task = loop.create_task(advertising_watchdog())
    # Seed network status once (off the BLE loop so nmcli doesn't stall startup);
    # net_status_loop also refreshes it periodically / on demand.
    try:
        status = await loop.run_in_executor(None, compute_device_status)
        _publish_net_status(status, notify=False)
    except Exception as e:
        logger.debug(f"initial net status failed: {e}")

    try:
        trigger.clear()
        if trigger.__module__ == "threading":
            trigger.wait()
        else:
            await trigger.wait()
    except KeyboardInterrupt:
        logger.debug("Shutting Down")
    finally:
        # Cancel the background tasks AND wait for them to actually finish before
        # tearing BlueZ down. The watchdog may be mid _reassert_advert()
        # (stop/start advertising) — if we let server.stop() run concurrently the
        # two would race over the same BlueZ/D-Bus advertisement resources and
        # produce a messy teardown. Awaiting the cancellation serialises it.
        net_task.cancel()
        advert_task.cancel()
        for t in (net_task, advert_task):
            try:
                await t
            except asyncio.CancelledError:
                pass
            except Exception as e:
                logger.debug(f"background task raised during shutdown: {e!r}")
    await server.stop()

try:
    loop.run_until_complete(run(loop))
except KeyboardInterrupt:
    logger.debug("Shutting Down")
    trigger.set()

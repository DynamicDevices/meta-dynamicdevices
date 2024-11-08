#!/usr/bin/env python3
# -*- coding: utf-8 -*-

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
import subprocess
import os

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

SERVER_HOST = "api.sentai.co.uk"
SERVICE_NAME = "Sentai"
CON_NAME = "improv"
INTERFACE = "wlan0"
TIMEOUT = 10000
FILENAME = "usr_token.json"
CONTAINERNAME = "sentaispeaker-SentaiSpeaker-1"
DIRPATH = "/var/rootdirs/home/fio/improv"
SERIALNUMBER = ""
IMEI = ""
ICCD = ""
WLAN_MAC = ""

loop = asyncio.get_event_loop()
server = BlessServer(name=SERVICE_NAME, loop=loop)

def wifi_connect(ssid: str, passwd: str, usrtoken: str) -> Optional[list[str]]:
    logger.warning(
        f"Creating Improv WiFi connection for '{ssid.decode('utf-8')}' with password: '{passwd.decode('utf-8')}' with password: '{usrtoken.decode('utf-8')}")

    try:
      nmcli.connection.delete(f"{CON_NAME}")
    except:
      print(f'No connection {CON_NAME} to remove')

    try:
      nmcli.connection.add('wifi', { 'ssid':ssid.decode('utf-8'), 'wifi-sec.key-mgmt':'wpa-psk', 'wifi-sec.psk':passwd.decode('utf-8') }, f"{INTERFACE}", f"{CON_NAME}", True)
    except:
      print(f'Could not add new connection {CON_NAME}')
      return None

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
    
    usertoken = usrtoken.decode('utf-8')    
    if not save_user_token(usertoken):
        print('Failed to save token')
        return None
    

    try:
        SERIALNUMBER = subprocess.check_output("cat /sys/devices/soc0/serial_number", shell=True, text=True).strip()
        print("Serial Number:", SERIALNUMBER)

        WLAN_MAC = subprocess.check_output("cat /sys/devices/soc0/serial_number", shell=True, text=True).strip()
        print("Mac Address:", WLAN_MAC)

    except subprocess.CalledProcessError as seriale:
        print("An error occurred when getting serial number and MAC:", seriale)

    try:
        modem_id = subprocess.check_output("mmcli -L | cut -c 42-42", shell=True, text=True).strip()
        print("MODEM_ID:", modem_id)

        
        if modem_id:
           
            IMEI = subprocess.check_output(f"mmcli -m {modem_id} | grep equipment | cut -c 35-", shell=True, text=True).strip()
            print("IMEI:", IMEI)
            
            
            ICCD = subprocess.check_output(f"mmcli --sim {modem_id} | grep 'iccid:' | cut -c 35-", shell=True, text=True).strip()
            print("ICCID Info:", ICCD)
            
    except subprocess.CalledProcessError as modeme:
        print("An error occurred getting modem details:", modeme)      
  
    server = f"https://{SERVER_HOST}?usertoken={usertoken}&ip_address={ip_addr}&mac_address={WLAN_MAC}&serial={SERIALNUMBER}&IMEI={IMEI}&ICCD={ICCD}"
    print("Return Value:", server)
    return [server]

def save_user_token(user_token):
   
    try:

        if not os.path.exists(DIRPATH):
            os.mkdir(DIRPATH)
        
        json_str = '{\n    "UserToken": "' + str(user_token) + '"\n}'
        filepath = os.path.join(DIRPATH, FILENAME)
        with open(filepath, 'w') as file:
            file.write(json_str)

        print(f"UserToken has been written to {FILENAME}")

    except Exception as fileex:
        print(f"An error occurred while writing the file: {fileex}")
        return False  

    try:
        
        copy_command = ['docker', 'cp', filepath, f'{CONTAINERNAME}:/app/']
        
        subprocess.run(copy_command, check=True)
        print(f"{FILENAME} has been copied to container '{CONTAINERNAME}'")

        return True  

    except subprocess.CalledProcessError as subex:
        print(f"An error occurred while copying the file to the container: {subex}")
        return False  

    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return False  # Return False for any other exceptions

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

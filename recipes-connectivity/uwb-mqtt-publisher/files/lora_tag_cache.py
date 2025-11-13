#!/usr/bin/env python3
"""
LoRa Tag Data Cache
Subscribes to TTN MQTT broker and caches LoRa tag data (battery, temperature, GPS, etc.)
Maps dev_eui to UWB IDs using configuration file

Copyright (c) Dynamic Devices Ltd. 2025. All rights reserved.
"""

import json
import ssl
import threading
import time
from datetime import datetime
from typing import Dict, Optional, Any

try:
    import paho.mqtt.client as mqtt
except ImportError as e:
    print("Error: paho-mqtt library not found. Install with: pip install paho-mqtt")
    raise


class LoraTagDataCache:
    """
    Subscribes to TTN MQTT broker and caches LoRa tag data.
    Provides thread-safe access to cached data mapped by UWB ID.
    """
    
    def __init__(self, 
                 broker: str = "eu1.cloud.thethings.network",
                 port: int = 8883,
                 username: str = None,
                 password: str = None,
                 topic_pattern: str = "#",
                 dev_eui_to_uwb_id_map: Dict[str, str] = None,
                 verbose: bool = False):
        """
        Initialize the LoRa tag data cache.
        
        Args:
            broker: MQTT broker hostname
            port: MQTT broker port
            username: MQTT username
            password: MQTT password
            topic_pattern: MQTT topic pattern to subscribe to (default: "#" for all topics)
            dev_eui_to_uwb_id_map: Dictionary mapping dev_eui (hex string) to UWB ID (hex string)
            verbose: Enable verbose logging
        """
        self.broker = broker
        self.port = port
        self.username = username
        self.password = password
        self.topic_pattern = topic_pattern
        self.dev_eui_to_uwb_id_map = dev_eui_to_uwb_id_map or {}
        self.verbose = verbose
        
        # Cache: dev_eui -> latest data
        self._cache: Dict[str, Dict[str, Any]] = {}
        self._cache_lock = threading.RLock()
        
        # Cache: UWB ID -> latest data (derived from dev_eui mapping)
        self._uwb_cache: Dict[str, Dict[str, Any]] = {}
        
        # MQTT client
        self.mqtt_client = None
        self._running = False
        self._thread = None
        
    def _log(self, message: str, level: str = "INFO"):
        """Internal logging method"""
        if self.verbose or level in ["ERROR", "WARNING"]:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"[{timestamp}] [LoRaCache {level}] {message}")
    
    def _on_connect(self, client, userdata, flags, rc):
        """MQTT connection callback"""
        if rc == 0:
            self._log(f"Connected to TTN MQTT broker {self.broker}:{self.port}")
            try:
                client.subscribe(self.topic_pattern, qos=0)
                self._log(f"Subscribed to topic pattern: {self.topic_pattern}")
            except Exception as e:
                self._log(f"Failed to subscribe: {e}", "ERROR")
        else:
            self._log(f"Failed to connect to MQTT broker (rc={rc})", "ERROR")
    
    def _on_disconnect(self, client, userdata, rc):
        """MQTT disconnection callback"""
        if rc != 0:
            self._log(f"Unexpected disconnection from MQTT broker (rc={rc})", "WARNING")
        else:
            self._log("Disconnected from MQTT broker")
    
    def _on_message(self, client, userdata, message):
        """MQTT message callback - processes LoRa tag data"""
        try:
            topic = message.topic
            payload = message.payload.decode('utf-8')
            
            self._log(f"Received message on topic: {topic}", "VERBOSE")
            
            # Parse JSON payload
            data = json.loads(payload)
            
            # Extract dev_eui
            dev_eui = None
            try:
                dev_eui = data.get("end_device_ids", {}).get("dev_eui", "").upper()
            except (AttributeError, KeyError):
                self._log(f"Could not extract dev_eui from message", "WARNING")
                return
            
            if not dev_eui:
                self._log(f"No dev_eui found in message", "WARNING")
                return
            
            # Extract decoded payload
            decoded_payload = {}
            try:
                uplink_msg = data.get("uplink_message", {})
                decoded_payload = uplink_msg.get("decoded_payload", {})
            except (AttributeError, KeyError):
                pass
            
            # Extract location data
            location_data = {}
            try:
                locations = uplink_msg.get("locations", {})
                if "frm-payload" in locations:
                    loc = locations["frm-payload"]
                    location_data = {
                        "latitude": loc.get("latitude"),
                        "longitude": loc.get("longitude"),
                        "altitude": loc.get("altitude"),
                        "accuracy": loc.get("accuracy"),
                        "source": loc.get("source")
                    }
            except (AttributeError, KeyError):
                pass
            
            # Extract metadata
            metadata = {
                "received_at": data.get("received_at"),
                "device_id": data.get("end_device_ids", {}).get("device_id"),
                "application_id": data.get("end_device_ids", {}).get("application_ids", {}).get("application_id"),
                "f_port": uplink_msg.get("f_port"),
                "f_cnt": uplink_msg.get("f_cnt"),
            }
            
            # Extract RX metadata (gateway info, RSSI, SNR)
            rx_metadata = []
            try:
                rx_list = uplink_msg.get("rx_metadata", [])
                for rx in rx_list:
                    rx_metadata.append({
                        "gateway_id": rx.get("gateway_ids", {}).get("gateway_id"),
                        "gateway_eui": rx.get("gateway_ids", {}).get("eui"),
                        "rssi": rx.get("rssi"),
                        "snr": rx.get("snr"),
                        "timestamp": rx.get("timestamp"),
                        "time": rx.get("time")
                    })
            except (AttributeError, KeyError):
                pass
            
            # Build cached data structure
            cached_data = {
                "dev_eui": dev_eui,
                "timestamp": time.time(),
                "received_at": metadata.get("received_at"),
                "decoded_payload": decoded_payload,
                "location": location_data,
                "metadata": metadata,
                "rx_metadata": rx_metadata
            }
            
            # Update cache
            with self._cache_lock:
                self._cache[dev_eui] = cached_data
                
                # Update UWB cache if mapping exists
                uwb_id = self.dev_eui_to_uwb_id_map.get(dev_eui)
                if uwb_id:
                    # Normalize UWB ID to uppercase hex string
                    uwb_id = uwb_id.upper()
                    self._uwb_cache[uwb_id] = cached_data
                    self._log(f"Cached data for dev_eui={dev_eui} -> UWB ID={uwb_id}", "VERBOSE")
                else:
                    self._log(f"No UWB mapping for dev_eui={dev_eui}", "VERBOSE")
            
        except json.JSONDecodeError as e:
            self._log(f"Failed to parse JSON payload: {e}", "ERROR")
        except Exception as e:
            self._log(f"Error processing message: {e}", "ERROR")
            if self.verbose:
                import traceback
                traceback.print_exc()
    
    def start(self):
        """Start the MQTT subscriber in a background thread"""
        if self._running:
            self._log("Cache already running", "WARNING")
            return
        
        self._running = True
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        self._log("LoRa tag cache started")
    
    def stop(self):
        """Stop the MQTT subscriber"""
        self._running = False
        if self.mqtt_client:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
        if self._thread:
            self._thread.join(timeout=5)
        self._log("LoRa tag cache stopped")
    
    def _run(self):
        """Run the MQTT client loop"""
        try:
            self.mqtt_client = mqtt.Client()
            self.mqtt_client.on_connect = self._on_connect
            self.mqtt_client.on_disconnect = self._on_disconnect
            self.mqtt_client.on_message = self._on_message
            
            # Set credentials if provided
            if self.username and self.password:
                self.mqtt_client.username_pw_set(self.username, self.password)
            
            # Configure TLS
            context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            self.mqtt_client.tls_set_context(context)
            
            # Connect
            self.mqtt_client.connect(self.broker, self.port, 60)
            
            # Run loop
            self.mqtt_client.loop_start()
            
            # Keep thread alive
            while self._running:
                time.sleep(1)
            
        except Exception as e:
            self._log(f"Error in MQTT loop: {e}", "ERROR")
            if self.verbose:
                import traceback
                traceback.print_exc()
        finally:
            if self.mqtt_client:
                self.mqtt_client.loop_stop()
                self.mqtt_client.disconnect()
    
    def get_by_dev_eui(self, dev_eui: str) -> Optional[Dict[str, Any]]:
        """
        Get cached data by dev_eui.
        
        Args:
            dev_eui: Device EUI (hex string, case-insensitive)
            
        Returns:
            Cached data dictionary or None if not found
        """
        dev_eui = dev_eui.upper()
        with self._cache_lock:
            return self._cache.get(dev_eui)
    
    def get_by_uwb_id(self, uwb_id: str) -> Optional[Dict[str, Any]]:
        """
        Get cached data by UWB ID (using dev_eui mapping).
        
        Args:
            uwb_id: UWB ID (hex string, case-insensitive)
            
        Returns:
            Cached data dictionary or None if not found
        """
        uwb_id = uwb_id.upper()
        with self._cache_lock:
            return self._uwb_cache.get(uwb_id)
    
    def get_all_cached(self) -> Dict[str, Dict[str, Any]]:
        """
        Get all cached data by UWB ID.
        
        Returns:
            Dictionary mapping UWB ID to cached data
        """
        with self._cache_lock:
            return self._uwb_cache.copy()
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """
        Get cache statistics.
        
        Returns:
            Dictionary with cache statistics
        """
        with self._cache_lock:
            return {
                "dev_eui_count": len(self._cache),
                "uwb_id_count": len(self._uwb_cache),
                "mapping_count": len(self.dev_eui_to_uwb_id_map),
                "dev_euis": list(self._cache.keys()),
                "uwb_ids": list(self._uwb_cache.keys())
            }


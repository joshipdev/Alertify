#!/usr/bin/env python3
"""
Alertify - Virtual ESP32 Hardware Simulator
Simulates the Alertify ESP32 device sending sensor telemetry,
heartbeat timestamps, and alert events to Firebase Realtime Database.

Usage:
    python3 tools/mock_esp32.py [--db-url URL] [--token TOKEN] [--device-id ID]
"""

import sys
import time
import json
import threading
import argparse
from urllib import request, error

DEFAULT_DEVICE_ID = "esp32_001"

class MockESP32:
    def __init__(self, db_url=None, auth_token=None, device_id=DEFAULT_DEVICE_ID):
        self.db_url = (db_url or "").rstrip("/")
        self.auth_token = auth_token
        self.device_id = device_id

        # Internal state
        self.armed = True
        self.alarm = False
        self.motion = False
        self.door_open = False
        self.smoke = False
        self.gas_raw = 420
        self.mq2_ready = True
        self.running = True

    def _make_url(self, path):
        if not self.db_url:
            return None
        url = f"{self.db_url}/{path}.json"
        if self.auth_token:
            url += f"?auth={self.auth_token}"
        return url

    def _send_patch(self, path, payload):
        url = self._make_url(path)
        if not url:
            return
        data = json.dumps(payload).encode("utf-8")
        req = request.Request(url, data=data, method="PATCH", headers={"Content-Type": "application/json"})
        try:
            with request.urlopen(req, timeout=4) as resp:
                pass
        except Exception as e:
            print(f"\n[Warning] Database write error ({path}): {e}")

    def _send_post(self, path, payload):
        url = self._make_url(path)
        if not url:
            return
        data = json.dumps(payload).encode("utf-8")
        req = request.Request(url, data=data, method="POST", headers={"Content-Type": "application/json"})
        try:
            with request.urlopen(req, timeout=4) as resp:
                pass
        except Exception as e:
            print(f"\n[Warning] Database event write error: {e}")

    def publish_snapshot(self):
        """Sends device status and sensor telemetry heartbeat."""
        now_ts = int(time.time())
        status_data = {
            "online": True,
            "armed": self.armed,
            "alarm": self.alarm or self.smoke or (self.armed and (self.motion or self.door_open)),
            "lastSeen": now_ts,
        }
        sensor_data = {
            "motion": self.motion,
            "smoke": self.smoke,
            "doorOpen": self.door_open,
            "gasRaw": self.gas_raw,
            "mq2Ready": self.mq2_ready,
        }

        if self.db_url:
            self._send_patch(f"devices/{self.device_id}/status", status_data)
            self._send_patch(f"devices/{self.device_id}/sensors", sensor_data)

        status_str = f"[ESP32 Heartbeat] Online: YES | Armed: {self.armed} | Motion: {self.motion} | Door: {'OPEN' if self.door_open else 'CLOSED'} | Gas: {self.gas_raw}"
        print(f"\r{status_str}", end="", flush=True)

    def publish_event(self, event_type, message):
        """Publishes an alert event to /events/<device_id>."""
        event = {
            "type": event_type,
            "message": message,
            "timestamp": int(time.time()),
            "gasRaw": self.gas_raw,
        }
        print(f"\n⚡ [ALERT EVENT] Type: {event_type} | {message}")
        if self.db_url:
            self._send_post(f"events/{self.device_id}", event)

    def heartbeat_loop(self):
        while self.running:
            self.publish_snapshot()
            time.sleep(5)

    def trigger_motion(self):
        print("\n🏃 [Simulating] Motion triggered!")
        self.motion = True
        self.publish_snapshot()
        self.publish_event("motion", "Motion detected at main entrance")

        def reset():
            time.sleep(4)
            self.motion = False
            self.publish_snapshot()
            print("\n✓ Motion cleared.")

        threading.Thread(target=reset, daemon=True).start()

    def toggle_door(self):
        self.door_open = not self.door_open
        state_str = "OPEN" if self.door_open else "CLOSED"
        print(f"\n🚪 [Simulating] Door is now {state_str}!")
        self.publish_snapshot()
        self.publish_event("door_open" if self.door_open else "door_closed", f"Door or window {state_str.lower()}")

    def toggle_smoke(self):
        self.smoke = not self.smoke
        self.gas_raw = 2450 if self.smoke else 420
        state_str = "DETECTED (Gas: 2450)" if self.smoke else "CLEARED (Gas: 420)"
        print(f"\n🔥 [Simulating] Smoke/Gas alert {state_str}!")
        self.publish_snapshot()
        if self.smoke:
            self.publish_event("smoke", "Smoke/gas threshold exceeded (raw: 2450)")

    def toggle_arm(self):
        self.armed = not self.armed
        state_str = "ARMED" if self.armed else "DISARMED"
        print(f"\n🛡️ [Simulating] System {state_str}!")
        self.publish_snapshot()
        self.publish_event("armed" if self.armed else "disarmed", f"System {state_str.lower()} via local controller")

def main():
    parser = argparse.ArgumentParser(description="Alertify Virtual ESP32 Hardware Simulator")
    parser.add_argument("--db-url", help="Firebase RTDB URL (e.g. https://your-app-default-rtdb.firebaseio.com)")
    parser.add_argument("--token", help="Firebase Database Auth Secret or ID Token (optional)")
    parser.add_argument("--device-id", default=DEFAULT_DEVICE_ID, help="Device ID (default: esp32_001)")
    args = parser.parse_args()

    print("=" * 60)
    print("      ALERTIFY - VIRTUAL ESP32 HARDWARE SIMULATOR")
    print("=" * 60)
    print(f"Device ID   : {args.device_id}")
    if args.db_url:
        print(f"Database URL: {args.db_url}")
    else:
        print("Database URL: [Standalone Mode - Local Testing Only]")
    print("-" * 60)
    print("Interactive Controls:")
    print("  [m] Trigger PIR Motion")
    print("  [d] Toggle MC-38 Door Contact (Open / Close)")
    print("  [g] Toggle MQ-2 Smoke / Gas Alert")
    print("  [a] Toggle System Armed / Disarmed")
    print("  [s] Force status snapshot now")
    print("  [q] Quit")
    print("=" * 60 + "\n")

    sim = MockESP32(db_url=args.db_url, auth_token=args.token, device_id=args.device_id)

    hb_thread = threading.Thread(target=sim.heartbeat_loop, daemon=True)
    hb_thread.start()

    try:
        while True:
            cmd = input().strip().lower()
            if cmd == "m":
                sim.trigger_motion()
            elif cmd == "d":
                sim.toggle_door()
            elif cmd == "g":
                sim.toggle_smoke()
            elif cmd == "a":
                sim.toggle_arm()
            elif cmd == "s":
                sim.publish_snapshot()
                print()
            elif cmd == "q":
                print("\nExiting Virtual ESP32 simulator.")
                sim.running = False
                break
            elif cmd == "h":
                print("Keys: [m]=Motion, [d]=Door, [g]=Smoke/Gas, [a]=Arm/Disarm, [s]=Sync, [q]=Quit")
    except (KeyboardInterrupt, EOFError):
        print("\nExiting.")
        sim.running = False

if __name__ == "__main__":
    main()

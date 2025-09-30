#!/usr/bin/env python3
from evdev import InputDevice, categorize, ecodes
import subprocess
import threading

# Replace with your actual devices from /dev/input/by-id/
keyboard_dev = '/dev/input/event18/Mouse
mouse_dev = '/dev/input/event19/Keyboard

# Start hidclient
hid = subprocess.Popen(['sudo', './hidclient', '-d', 'hidd', '-c'], stdin=subprocess.PIPE)

def forward_input(device_path):
    dev = InputDevice(device_path)
    for event in dev.read_loop():
        if event.type == ecodes.EV_KEY:
            key_event = categorize(event)
            if key_event.keystate == key_event.key_down:
                hid.stdin.write(f"keydown {key_event.keycode}\n".encode())
            elif key_event.keystate == key_event.key_up:
                hid.stdin.write(f"keyup {key_event.keycode}\n".encode())
        elif event.type == ecodes.EV_REL:  # Mouse movement
            if event.code == ecodes.REL_X:
                hid.stdin.write(f"mousemove {event.value} 0\n".encode())
            elif event.code == ecodes.REL_Y:
                hid.stdin.write(f"mousemove 0 {event.value}\n".encode())
        elif event.type == ecodes.EV_KEY and 'BTN_' in ecodes.keys[event.code]:
            if event.value == 1:
                hid.stdin.write(f"mousedown {event.code}\n".encode())
            elif event.value == 0:
                hid.stdin.write(f"mouseup {event.code}\n".encode())
        hid.stdin.flush()

# Run keyboard and mouse forwarding in parallel threads
threading.Thread(target=forward_input, args=(keyboard_dev,), daemon=True).start()
threading.Thread(target=forward_input, args=(mouse_dev,), daemon=True).start()

# Keep script running
input("Press Enter to exit...\n")

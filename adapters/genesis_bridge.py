"""
Kratos Genesis Bridge Adapter
─────────────────────────────
Bridges ROS2 topics (via rosbridge WebSocket) to a Genesis physics simulation.
Runs natively on macOS (Apple Silicon / Metal) alongside the containerised ROS2 stack.

Usage:
    kratos start                          # start the container first
    python adapters/genesis_bridge.py     # then run this on the host

Architecture:
    ┌──────────────┐  WebSocket   ┌──────────────────────┐
    │  ROS2 Stack  │◄────────────►│  This adapter        │
    │  (container) │  :9090       │  (macOS host)        │
    │  rosbridge   │              │  Genesis + roslibpy  │
    └──────────────┘              └──────────────────────┘
"""

import time
import math
import roslibpy

# ── Connect to rosbridge in the container ───────────────────────────
ROSBRIDGE_HOST = "localhost"
ROSBRIDGE_PORT = 9090

print(f"[bridge] Connecting to rosbridge at ws://{ROSBRIDGE_HOST}:{ROSBRIDGE_PORT} ...")
ros = roslibpy.Ros(host=ROSBRIDGE_HOST, port=ROSBRIDGE_PORT)
ros.run()

if ros.is_connected:
    print("[bridge] ✓ Connected to rosbridge")
else:
    print("[bridge] ✗ Failed to connect. Is the container running? (kratos start)")
    exit(1)

# ── ROS topics ──────────────────────────────────────────────────────
scan_pub = roslibpy.Topic(ros, "/scan", "sensor_msgs/LaserScan")
cmd_sub = roslibpy.Topic(ros, "/cmd_vel", "geometry_msgs/Twist")

# ── Genesis init ────────────────────────────────────────────────────
# Uncomment when Genesis is installed:
# import genesis as gs
# gs.init(backend=gs.gpu)  # resolves to Metal on Apple Silicon
# scene = gs.Scene()
# # ... add your robot, environment, sensors here ...

# ── State ───────────────────────────────────────────────────────────
latest_cmd = {"linear_x": 0.0, "angular_z": 0.0}


def on_cmd_vel(msg):
    """Receive velocity commands from ROS2 (e.g. teleop_twist_keyboard)."""
    latest_cmd["linear_x"] = msg["linear"]["x"]
    latest_cmd["angular_z"] = msg["angular"]["z"]
    print(f"[bridge] cmd_vel: linear={msg['linear']['x']:.2f}  angular={msg['angular']['z']:.2f}")


cmd_sub.subscribe(on_cmd_vel)
print("[bridge] Subscribed to /cmd_vel")
print("[bridge] Publishing to /scan")


def make_laser_scan(ranges, num_readings=360):
    """Build a LaserScan message dict for rosbridge."""
    now = time.time()
    return {
        "header": {
            "stamp": {"sec": int(now), "nanosec": int((now % 1) * 1e9)},
            "frame_id": "base_scan",
        },
        "angle_min": 0.0,
        "angle_max": 2 * math.pi,
        "angle_increment": (2 * math.pi) / num_readings,
        "time_increment": 0.0,
        "scan_time": 0.1,
        "range_min": 0.12,
        "range_max": 3.5,
        "ranges": ranges,
        "intensities": [],
    }


# ── Simulation loop ────────────────────────────────────────────────
print("[bridge] Starting simulation loop (Ctrl+C to stop)...")
print("[bridge] NOTE: Replace the dummy scan data below with actual Genesis sensor output.")

try:
    while ros.is_connected:
        # TODO: Step Genesis simulation here
        # scene.step()

        # TODO: Apply latest_cmd to your Genesis robot entity
        # robot.set_velocity(latest_cmd["linear_x"], latest_cmd["angular_z"])

        # TODO: Read lidar sensor from Genesis and publish
        # For now, publish dummy scan data (3.5m = max range = no obstacle)
        dummy_ranges = [3.5] * 360
        scan_pub.publish(roslibpy.Message(make_laser_scan(dummy_ranges)))

        time.sleep(0.1)  # ~10 Hz

except KeyboardInterrupt:
    print("\n[bridge] Shutting down...")
finally:
    cmd_sub.unsubscribe()
    scan_pub.unadvertise()
    ros.terminate()
    print("[bridge] Disconnected.")

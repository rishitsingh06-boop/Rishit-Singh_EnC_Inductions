#!/usr/bin/env python3

import math
import sys

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState


class ArmIKController(Node):

    JOINT_NAMES = [
    "base_yaw_joint",
    "shoulder_joint",
    "elbow_joint",
    "wrist_pitch_joint",
    "wrist_roll_joint",
    "gripper_servo_joint"
 ]

    def __init__(self):
        super().__init__('arm_ik_controller')

        # ---- Kinematic model parameters (override via --ros-args -p) ----
        # Robot dimensions
        self.L1 = 1.20          # Shoulder to elbow
        self.L2 = 1.30          # Elbow to wrist
        self.base_height = 0.40 # Base to shoulder

        # IK configuration
        self.elbow_up = True

        self._publisher = self.create_publisher(JointState, '/joint_states', 10)

        # Internal state -- the single source of truth for where the
        # end effector currently is and which joint angles produced it.
        self.current_position = {
            'x': 2.10,
            'y': 0.75,
            'z': 0,
        }
        self.current_joint_angles = None  # dict: base_yaw, shoulder, elbow

        # Establish the initial joint configuration for the initial position.
        reachable, angles_or_error = self.solve_ik(**self.current_position)
        if not reachable:
            raise RuntimeError(
                f'Initial position {self.current_position} is not reachable: '
                f'{angles_or_error}'
            )
        self.current_joint_angles = angles_or_error
        self.publish_joint_state(self.current_joint_angles)
        self.get_logger().info(
         f"Initialized end effector at "
         f"x={self.current_position['x']:.2f}, "
         f"y={self.current_position['y']:.2f}, "
         f"z={self.current_position['z']:.2f}"
        )

    # ------------------------------------------------------------------
    # Inverse kinematics
    # ------------------------------------------------------------------
    def solve_ik(self, x, y, z):
        
        L1, L2 = self.L1, self.L2

        r = math.hypot(x, y)  # horizontal distance from the yaw axis

        if r < 1e-9 and abs(z - self.base_height) < 1e-9:
            return False, 'Target coincides with the base yaw axis (singularity).'

        base_yaw = math.atan2(y, x)

        # Reduce to a 2-link planar IK problem in the plane picked by base_yaw.
        z_rel = z - self.base_height
        d = math.hypot(r, z_rel)  # distance from shoulder joint to target

        reach_max = L1 + L2
        reach_min = abs(L1 - L2)
        if d > reach_max + 1e-9:
            return False, (
                f'Target is too far away: required reach {d:.3f} m exceeds '
                f'the maximum reach of {reach_max:.3f} m '
                f'(link1={L1:.3f} m + link2={L2:.3f} m).'
            )
        if d < reach_min - 1e-9:
            return False, (
                f'Target is too close: required reach {d:.3f} m is below '
                f'the minimum reach of {reach_min:.3f} m '
                f'(|link1={L1:.3f} m - link2={L2:.3f} m|).'
            )

        # Law of cosines for the elbow angle.
        cos_elbow = (d * d - L1 * L1 - L2 * L2) / (2 * L1 * L2)
        cos_elbow = max(-1.0, min(1.0, cos_elbow))  # guard floating point noise
        elbow_mag = math.acos(cos_elbow)
        elbow = elbow_mag if self.elbow_up else -elbow_mag

        # Shoulder angle from geometric triangle + elbow contribution.
        shoulder = math.atan2(z_rel, r) - math.atan2(
            L2 * math.sin(elbow), L1 + L2 * math.cos(elbow)
        )

        return True, {'base_yaw': base_yaw, 'shoulder': shoulder, 'elbow': elbow}

    # ------------------------------------------------------------------
    # Publishing
    # ------------------------------------------------------------------
    def publish_joint_state(self, angles):
        msg = JointState()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.name = list(self.JOINT_NAMES)
        msg.position = [
        angles["base_yaw"],
        angles["shoulder"],
        angles["elbow"],
        0.0,
        0.0,
        0.0
      ]
        msg.velocity = []
        msg.effort = []
        self._publisher.publish(msg)

    # ------------------------------------------------------------------
    # Command handling
    # ------------------------------------------------------------------
    def apply_displacement(self, axis, distance):
        
        target = dict(self.current_position)
        target[axis] += distance

        reachable, result = self.solve_ik(**target)
        if not reachable:
            self.get_logger().error(
            f"Rejected move along {axis} by {distance:+.3f} m -> "
            f"Target: "
            f"x={target['x']:.2f}, "
            f"y={target['y']:.2f}, "
            f"z={target['z']:.2f}. "
            f"{result}"
            )
            print(f'ERROR: command rejected -- {result}')
            print('Previous configuration preserved.')
            return False

        # Success: commit the new state and publish.
        self.current_position = target
        self.current_joint_angles = result
        self.publish_joint_state(result)
        self.get_logger().info(
          f"Initial Position -> "
          f"x={self.current_position['x']:.2f}, "
          f"y={self.current_position['y']:.2f}, "
          f"z={self.current_position['z']:.2f}"
          )
        
        return True


def prompt_and_run(node: ArmIKController):
    print('=== Robotic Arm IK Controller ===')
    print("Type 'q' at any prompt to quit.\n")

    while rclpy.ok():
        pos = node.current_position
        print('Current End Effector Position:')
        print(f"x = {pos['x']:.2f}")
        print(f"y = {pos['y']:.2f}")
        print(f"z = {pos['z']:.2f}")

        axis = input('Enter axis to move (x/y/z): ').strip().lower()
        if axis in ('q', 'quit', 'exit'):
            break
        if axis not in ('x', 'y', 'z'):
            print('ERROR: axis must be one of x, y, z.\n')
            continue

        raw = input('Enter displacement (meters): ').strip()
        if raw.lower() in ('q', 'quit', 'exit'):
            break
        try:
            distance = float(raw)
        except ValueError:
            print('ERROR: displacement must be a number.\n')
            continue

        node.apply_displacement(axis, distance)
        print()


def main(args=None):
    rclpy.init(args=args)
    try:
        node = ArmIKController()
    except RuntimeError as exc:
        print(f'Failed to start arm_ik_controller: {exc}', file=sys.stderr)
        rclpy.shutdown()
        return 1

    try:
        prompt_and_run(node)
    except (KeyboardInterrupt, EOFError):
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
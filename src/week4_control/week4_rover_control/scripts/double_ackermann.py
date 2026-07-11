#!/usr/bin/env python3
import math
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from std_msgs.msg import Float64MultiArray

class DoubleAckermannController(Node):
    def __init__(self):
        super().__init__('double_ackermann_controller')
        
        # Subscribe to teleop/joystick commands
        self.cmd_sub = self.create_subscription(
            Twist, 
            '/cmd_vel', 
            self.cmd_callback, 
            10
        )
        
        # Publisher for the 4 steering hinges (Position in Radians)
        # Order matches YAML: [fl_steer, fr_steer, rl_steer, rr_steer]
        self.steer_pub = self.create_publisher(
            Float64MultiArray, 
            '/steering_controller/commands', 
            10
        )

        # Publisher for the 4 wheel axles (Velocity in Rad/s)
        # Order matches YAML: [fl_drive, fr_drive, rl_drive, rr_drive]
        self.drive_pub = self.create_publisher(
            Float64MultiArray, 
            '/drive_controller/commands', 
            10
        )

        # Rover Physical Constants
        self.wheelbase = 0.5 
        self.track_width = 0.3
        self.wheel_radius = 0.12

        # Steering joint hardware limits (radians)
        self.steer_min = -1.57
        self.steer_max = 1.57

        # Below this angular speed we just treat the motion as a
        # straight line, otherwise dividing by omega would blow up.
        self.omega_epsilon = 1e-3

        self.get_logger().info("Double Ackermann Controller Node Started. Waiting for /cmd_vel...")

    def compute_wheel(self, x_offset, y_offset, turn_radius, angular_z):
        """Compute the steering angle and wheel speed for one wheel.

        In a double Ackermann rover, the front AND rear axles steer,
        both pointing toward the same turning center (ICR). This
        center sits on the y-axis at distance 'turn_radius' from the
        middle of the rover.

        x_offset: distance of the wheel from the rover center along
                  the forward axis (+ for front wheels, - for rear).
        y_offset: distance of the wheel from the rover center along
                  the left axis (+ for left wheels, - for right).
        turn_radius: signed distance from the rover center to the ICR.
        angular_z: the commanded turn rate (rad/s), used to get the
                   direction and speed of the wheel.

        Returns a tuple: (steering_angle_rad, wheel_velocity_rad_s)
        """
        # Vector from the wheel to the ICR, measured along the
        # forward axis and the left axis.
        forward_component = x_offset
        left_component = turn_radius - y_offset

        # The wheel must point perpendicular to the line joining it
        # to the ICR, which is exactly what atan2 gives us here.
        angle = math.atan2(forward_component, left_component)

        # Clamp to the physical steering limits of the hinge.
        angle = max(self.steer_min, min(self.steer_max, angle))

        # Distance from this wheel to the ICR sets how fast it must
        # spin to keep up with the rest of the rover during the turn.
        distance_to_icr = math.sqrt(forward_component ** 2 + left_component ** 2)
        wheel_speed = angular_z * distance_to_icr / self.wheel_radius

        return angle, wheel_speed

    def cmd_callback(self, msg):
        """Convert an incoming /cmd_vel Twist into 4 steering angles
        and 4 wheel velocities using double Ackermann kinematics, then
        publish them to the steering and drive controllers.
        """
        linear_x = msg.linear.x
        angular_z = msg.angular.z

        # Half wheelbase / half track width, used repeatedly below.
        half_wheelbase = self.wheelbase / 2.0
        half_track = self.track_width / 2.0

        if abs(angular_z) < self.omega_epsilon:
            # Driving (almost) straight: no steering needed, and every
            # wheel just spins at the same speed.
            fl_angle = fr_angle = rl_angle = rr_angle = 0.0
            wheel_speed = linear_x / self.wheel_radius
            fl_vel = fr_vel = rl_vel = rr_vel = wheel_speed
        else:
            # Turning radius from the rover's center point to the ICR.
            turn_radius = linear_x / angular_z

            # Wheel positions relative to the rover center:
            # x_offset: +front / -rear, y_offset: +left / -right
            fl_angle, fl_vel = self.compute_wheel(half_wheelbase, half_track, turn_radius, angular_z)
            fr_angle, fr_vel = self.compute_wheel(half_wheelbase, -half_track, turn_radius, angular_z)
            rl_angle, rl_vel = self.compute_wheel(-half_wheelbase, half_track, turn_radius, angular_z)
            rr_angle, rr_vel = self.compute_wheel(-half_wheelbase, -half_track, turn_radius, angular_z)

        # Publish Steering Commands
        steer_msg = Float64MultiArray()
        steer_msg.data = [fl_angle, fr_angle, rl_angle, rr_angle]
        self.steer_pub.publish(steer_msg)

        # Publish Drive Commands
        drive_msg = Float64MultiArray()
        drive_msg.data = [fl_vel, fr_vel, rl_vel, rr_vel]
        self.drive_pub.publish(drive_msg)

def main(args=None):
    rclpy.init(args=args)
    node = DoubleAckermannController()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
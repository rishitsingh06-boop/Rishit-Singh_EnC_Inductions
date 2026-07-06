#!/usr/bin/env python3

import rclpy
from rclpy.node import Node

from kratos_rishit_msgs.msg import RoverStatus


class RoverStatusSubscriber(Node):

    def __init__(self):
        super().__init__("rover_status_msg_subscriber")

        self.subscription = self.create_subscription(
            RoverStatus,
            "/rover_status",
            self.callback,
            10
        )

    def callback(self, msg):

        self.get_logger().info(
            f"Battery: {msg.battery_percentage}%"
        )

        self.get_logger().info(
            f"Velocity: {msg.velocity} m/s"
        )

        self.get_logger().info(
            f"Emergency Stop: {msg.emergency_stop}"
        )

        self.get_logger().info(
            f"Mode: {msg.mode}"
        )


def main(args=None):
    rclpy.init(args=args)

    node = RoverStatusSubscriber()

    rclpy.spin(node)

    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
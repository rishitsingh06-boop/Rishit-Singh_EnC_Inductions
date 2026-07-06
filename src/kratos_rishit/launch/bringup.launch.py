from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():

    return LaunchDescription([
        Node(
            package='kratos_rishit',
            executable='rover_status_msg_publisher',
            name='rover_status_msg_publisher',
            output='screen'
        ),

        Node(
            package='kratos_rishit',
            executable='rover_status_msg_subscriber',
            name='rover_status_msg_subscriber',
            output='screen'
        )
    ])
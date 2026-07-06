import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration, Command
from launch_ros.actions import Node

def generate_launch_description():
    # 1. Get the package directory
    pkg_share = get_package_share_directory('arm_humble') # <-- CHANGE TO YOUR ACTUAL PACKAGE NAME
    
    # 2. Define paths to assets
    xacro_file = os.path.join(pkg_share, 'urdf', 'my_custom_arm.urdf.xacro')
    rviz_config_file = os.path.join(pkg_share, 'rviz', 'view_arm.rviz')

    # 3. Process Xacro to plain URDF string using Command substitution
    robot_description_raw = Command(['xacro ', xacro_file])

    # 4. Configure nodes
    robot_state_publisher_node = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        output='screen',    
        parameters=[{'robot_description': robot_description_raw}]
    )

   

    rviz2_node = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        arguments=['-d', rviz_config_file]
    )

    # 5. Return Launch Description
    return LaunchDescription([
        robot_state_publisher_node,
        
        rviz2_node
    ])

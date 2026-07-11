import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node
import xacro

def generate_launch_description():
    # 1. Get the path to your package and xacro file
    pkg_path = os.path.join(get_package_share_directory('rover_description'))
    xacro_file = os.path.join(pkg_path, 'urdf', 'kratos_rover.urdf.xacro')

    # 2. Process the Xacro file into a raw URDF string
    robot_description_config = xacro.process_file(xacro_file)
    robot_description = {'robot_description': robot_description_config.toxml()}

    # 3. Start the Robot State Publisher Node
    node_robot_state_publisher = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        output='screen',
        parameters=[robot_description]
    )

    # 4. Start the Joint State Publisher GUI
    node_joint_state_publisher_gui = Node(
        package='joint_state_publisher_gui',
        executable='joint_state_publisher_gui',
        name='joint_state_publisher_gui'
    )

    # Find the path to your saved config
    rviz_config_file = os.path.join(pkg_path, 'rviz', 'kratos_config.rviz')

    # 5. Start RViz2
    # If you have a saved RViz config file, you can point to it here. 
    # Otherwise, it will open a blank RViz window.
    node_rviz = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        arguments=['-d', rviz_config_file] # Optional: specify your RViz config file
    )

    # Launch them all!
    return LaunchDescription([
        node_robot_state_publisher,
        node_joint_state_publisher_gui,
        node_rviz
    ])
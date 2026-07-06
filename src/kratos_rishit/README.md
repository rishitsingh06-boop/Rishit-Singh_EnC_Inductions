# ROS2 Basics Assignment

# Question 1

## Approach
- Created publisher nodes for battery level, rover mode, and emergency stop.
- Implemented a subscriber node to receive and print all three topics.
- Verified communication using ROS2 CLI tools.

## Assumptions
- ROS2 Humble is installed and the workspace is sourced.

## Challenges Encountered
- Understanding publishers, subscribers, and ROS2 topics.

## Testing
- Used `ros2 node list`, `ros2 topic list`, `ros2 topic type`, and `ros2 topic echo`.
- Verified all topics and messages were published correctly.

## Known Limitations
- Published values are hardcoded.

---

# Question 2

## Approach
- Created a custom `RoverStatus.msg`.
- Implemented publisher and subscriber nodes using the custom message.
- Added a launch file (`bringup.launch.py`) to launch all nodes together.

## Assumptions
- Custom message package builds successfully before running the nodes.

## Challenges Encountered
- Configuring custom message generation and package dependencies.

## Testing
- Verified the custom message using `ros2 interface show`.
- Confirmed successful publishing and subscription of `RoverStatus` messages.

## Known Limitations
- Message values are hardcoded for demonstration purposes.
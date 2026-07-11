# Kratos Rover: Double Ackermann Kinematics Assignment

Welcome! In this assignment, you will write a controller for a 4-wheel independent drive and steer rover.

You will take standard joystick commands and convert them into the specific steering angles and wheel velocities required to drive the rover using Double Ackermann steering geometry.

---

## System Requirements
This assignment is built for **ROS 2 Humble** running on **Ubuntu 22.04**. 
You are expected to have the `ros-humble-desktop` environment installed.

## Step 1: Install System Dependencies
Before cloning this repository, you must install the standard simulation bridges and hardware interfaces required to run in Gazebo Classic.

Run the following command to install the required packages:

```bash
sudo apt update
sudo apt install gazebo11 \
                 libgazebo11-dev \
                 ros-humble-gazebo-ros-pkgs \
                 ros-humble-gazebo-ros2-control \
                 ros-humble-ros2-control \
                 ros-humble-ros2-controllers \
                 ros-humble-teleop-twist-keyboard

```

## Step 2: Getting the packages
1. Go to the **src** folder of your existing workspace.

```bash
cd ~/<your_workspace>/src 
```
2. Clone this assignment repo

```bash
git clone https://github.com/ayush-shukla03/week4_control.git
```

3. Go back to the root of the workspace, build and source the installation
```bash
cd ..
colcon build
source install/setup.bash
```

## Your Task
Navigate to **src/week4_control/scripts/double_ackermann.py**. This is the only file you need to modify.
Your task is to modify the **cmd_callback** function.
1. Subscribe to **/cmd_vel** topic.
2. Calculate the required Double Ackermann steering angles (in radians) and wheel velocities (in rad/s).
3. Publish standard Float64MultiArray messages to the ros2_control hardware interfaces.

Rover Specifications

Wheelbase: 0.4 m

Track Width: 0.6 m

Wheel Radius: 0.12 m

Steering Joint Limits: -1.57 rad to +1.57 rad (±90 degrees).

## Submission
You are supposed to push the completed package **week4_rover_control** to the src folder of your existing Github repo from the previous weeks.

**Terminal 1: Launch Gazebo and spawn your rover**
```bash
cd ~/<your_workspace>/
colcon build
source install/setup.bash
ros2 launch week4_rover_control sim.launch.py
```

**Terminal 2: Run your controller node**
```bash
source install/setup.bash
ros2 run week4_rover_control controller
```

**Terminal 3: Run keyboard teleop node**
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

Also submit a video showcasing all these terminals and rover movement in Gazebo. You have to push the code the to the existing Github repo that you have been working in. You have to push two packages in the src folder - rover_description and week4_rover_control(completed). 
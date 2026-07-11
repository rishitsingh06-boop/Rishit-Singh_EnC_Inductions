# Kratos Rover: Double Ackermann Kinematics Assignment

Welcome to Week 4! In this assignment, you will write a Kinematic Controller for a 4-wheel independent drive and steer rover.

---

## 🚦 Phase 1: Environment Preparation

### Track A: Returning Applicants (Update Required)
If you have already completed previous weeks and have the `kratos` CLI installed on your host machine, you must update your core Docker image. We have added new Gazebo and ROS 2 Control dependencies for this assignment. If you skip this, your simulation will crash.

Open a terminal on your host machine (Mac or Linux) and run:
```bash
docker pull ayushshukladocker/kratos-dev:latest
```

### Track B: New Applicants (First-Time Setup)
If this is your first time setting up the Kratos environment, you need to run the initial induction scripts. This will install Docker, configure your GPU (if applicable), pull the image, and install the `kratos` CLI.

1. Clone the docker induction repository to your host machine. [Link to the repo](https://github.com/project-kratos-lab/induction_docker_repo.git)

2. Run the setup script appropriate for your operating system:

Linux: 
```bash
sudo ./setup.sh
```

macOS:
```bash
./setup_mac.sh
```

(Once the script says "Setup complete", proceed to Phase 2).

## 💻 Phase 2: Starting the Workspace
Once your image is up to date, it is time to boot the container and pull the assignment code.

1. Start the Container
Open a terminal on your host machine and launch the environment:
```bash
kratos start
kratos shell
```
(You are now inside the Docker's container terminal)

2. Clone the Assignment 
Navigate to the **src** folder of your workspace and pull the Week 4 code:
```bash
cd /<your_workspace>/src
git clone https://github.com/ayush-shukla03/week4_control.git
```

3. Build the packages 
Navigate back to the root of your workspace to compile the new packages:
```bash
cd /<your_workspace>
colcon build --packages-select week4_rover_control rover_description
source install/setup.bash
```

## 🚀 Phase 3: Running the Simulation

You will need 3 separate terminal windows inside your container to run the full simulation stack.

### Terminal 1: Start Gazebo
To ensure the simulation renders correctly in your browser's VNC viewer (especially for Macs without dedicated GPUs), use the software rendering flag:

```bash
export GAZEBO_MODEL_DATABASE_URI=""
export LIBGL_ALWAYS_SOFTWARE=1
cd /workspace
source install/setup.bash
ros2 launch week4_rover_control sim.launch.py  
```
### 🖥️ How to View the Simulation

Gazebo is now running inside the container, but you need to connect your browser to see it.

1. Open Chrome, Firefox, or Safari on your host machine.
2. Navigate to: `http://localhost:6080/vnc.html`
3. Click `Connect`.
4. You should see a Linux desktop environment. If Terminal 1 launched successfully, Gazebo should be open with the rover sitting on the grid

### Terminal 2: Run your controller node
This runs the Python script where you will write your Double Ackermann kinematics:

```bash
cd ~/<your_workspace>/
source install/setup.bash
ros2 run week4_rover_control controller
```

### Terminal 3: Teleop Keyboard Control
Use standard keyboard inputs (I, J, K, L) to send velocity commands to your controller:

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```



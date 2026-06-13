# Project Kratos development environment
For people who can't set up Ubuntu 22
---

## Quick Start

### Linux

```bash
# One-time setup (installs Docker, GPU toolkit, pulls image, installs CLI)
chmod +x setup.sh kratos
./setup.sh

# Start the environment
kratos start

# Open the desktop in your browser
# → http://localhost:6080/vnc.html

# Open a terminal inside the container
kratos shell

# Stop when done
kratos stop
```

### macOS

```bash
# One-time setup (installs Docker Desktop, Genesis venv, CLI)
chmod +x setup_mac.sh kratos
./setup_mac.sh

# Start (also activates Genesis venv automatically)
kratos start

# Desktop: http://localhost:6080/vnc.html
# Genesis bridge: python adapters/genesis_bridge.py
```

---

## What You Get

| Port | Service | What it does |
|------|---------|-------------|
| 6080 | noVNC | Full Linux desktop in your browser (RViz2, Gazebo, rqt) |
| 9090 | rosbridge | WebSocket bridge so macOS Genesis can talk to ROS2 |

### Inside the Container

Everything is pre-installed and ready:

```bash
# Launch TurtleBot3 in Gazebo
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py

# Open RViz2 (in another terminal: kratos shell)
rviz2

# Teleop keyboard control
ros2 run turtlebot3_teleop teleop_keyboard

# Launch Nav2 navigation
ros2 launch turtlebot3_navigation2 navigation2.launch.py use_sim_time:=true map:=/path/to/map.yaml

# See all running topics
ros2 topic list

# RQT tools
rqt
rqt_graph
```

### Your Workspace

- Host: `~/ros2_ws/` → Container: `/workspace/`
- Files you create on either side appear on both
- Files are owned by **your user** (not root)

```bash
# Build your own ROS2 packages inside the container
cd /workspace
mkdir -p src
# put your packages in src/
colcon build
source install/setup.bash
```

---

## Commands

```
kratos start    Start the dev container + noVNC desktop
kratos stop     Stop the dev container
kratos status   Check if the container is running
kratos shell    Open a bash shell inside the container (ROS2 pre-sourced)
```

---

## Troubleshooting

**"Permission denied" on docker commands**
```bash
sudo usermod -aG docker $USER
newgrp docker    # or log out and back in
```
**Apt can't find any package**
```bash
sudo apt update
sudo apt install [package]
```


**Container starts but noVNC doesn't load**
```bash
./kratos-env.sh status     # is it running?
docker logs kratos_dev     # check for errors
```

**"kratos-env.sh: command not found"**
```bash
# Either run from the repo directory:
./kratos-env.sh start

# Or install to PATH:
sudo cp kratos-env.sh /usr/local/bin/kratos
```

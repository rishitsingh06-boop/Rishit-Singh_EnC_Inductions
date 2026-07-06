FROM osrf/ros:humble-desktop-full

# ── System packages ─────────────────────────────────────────────────
# VNC + window manager, ROS2 tools, Nav2, TurtleBot3, rosbridge, dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    fluxbox tigervnc-standalone-server \
    ros-humble-rviz2 ros-humble-rqt ros-humble-rqt-common-plugins ros-humble-rqt-graph \
    ros-humble-joint-state-publisher \
    ros-humble-navigation2 ros-humble-nav2-bringup \
    ros-humble-turtlebot3 ros-humble-turtlebot3-gazebo ros-humble-turtlebot3-teleop \
    ros-humble-rosbridge-suite \
    python3-pip git curl wget nano \
    sudo gosu \
    && rm -rf /var/lib/apt/lists/*

# ── noVNC (browser-based VNC client) — pinned to release tags ───────
RUN git clone --depth 1 --branch v1.5.0 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 --branch v0.12.0 https://github.com/novnc/websockify /opt/novnc/utils/websockify

# ── Environment ─────────────────────────────────────────────────────
ENV DISPLAY=:1
ENV TURTLEBOT3_MODEL=waffle

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080 9090

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]

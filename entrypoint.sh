#!/bin/bash
# Kratos container entrypoint
# Creates a dev user, starts the VNC + noVNC stack, sources ROS2, launches rosbridge.

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

log()  { echo -e "${BLUE}[kratos-dev]${NC} $1"; }
ok()   { echo -e "${GREEN}[kratos-dev]${NC} $1"; }
fail() { echo -e "${RED}[kratos-dev]${NC} $1" >&2; }

# User setup — match host UID/GID so workspace files have correct ownership
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"
UNAME="kratos"

log "Setting up user ${UNAME} (UID=${HOST_UID}, GID=${HOST_GID})..."

if ! getent group "$HOST_GID" &>/dev/null; then
    groupadd -g "$HOST_GID" kratosgrp
fi
GNAME=$(getent group "$HOST_GID" | cut -d: -f1)

if ! id "$UNAME" &>/dev/null 2>&1; then
    useradd -m -u "$HOST_UID" -g "$HOST_GID" -s /bin/bash -d /workspace "$UNAME" 2>/dev/null || true
fi

echo "${UNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/kratos
chmod 0440 /etc/sudoers.d/kratos
ok "User ${UNAME} created with passwordless sudo"

# Home & dotfiles
export HOME=/workspace
mkdir -p "$HOME/.vnc" "$HOME/.config/fluxbox" "$HOME/.ros" "$HOME/.gazebo" "$HOME/.rviz2"
chown -R "$HOST_UID:$HOST_GID" "$HOME/.vnc" "$HOME/.config" "$HOME/.ros" "$HOME/.gazebo" "$HOME/.rviz2" 2>/dev/null || true

# Clean stale locks from previous runs
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# VNC
log "Starting VNC server on display :1 ..."
Xvnc :1 \
    -geometry 1600x900 -depth 24 -rfbport 5901 \
    -SecurityTypes None -AlwaysShared \
    -AcceptKeyEvents -AcceptPointerEvents \
    -SendCutText -AcceptCutText &
VNC_PID=$!
sleep 1

if ! kill -0 $VNC_PID 2>/dev/null; then
    fail "VNC server failed to start"
    exit 1
fi
ok "VNC server running (PID $VNC_PID)"

# Fluxbox
log "Starting fluxbox..."
fluxbox &>/dev/null &
sleep 0.5

# noVNC
log "Starting noVNC on port 6080..."
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6080 &>/dev/null &
sleep 0.5
ok "noVNC ready"

# ROS2
log "Sourcing ROS2 Humble..."
source /opt/ros/humble/setup.bash

if [ -f /workspace/install/setup.bash ]; then
    log "Found workspace overlay, sourcing..."
    source /workspace/install/setup.bash
fi

# Rosbridge
log "Launching rosbridge on ws://0.0.0.0:9090 ..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:=9090 &>/dev/null &
sleep 1
ok "Rosbridge running"

# Done — keep alive
log "Container running. Attach with: kratos shell"
wait $VNC_PID

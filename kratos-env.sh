#!/bin/bash
# ── Kratos Dev Environment Launcher ─────────────────────────────────
# Usage: kratos {start|stop|status|shell|reset}
set -e
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
ORIG_ARGS="$*"

# ── Config ──────────────────────────────────────────────────────────
IMAGE="ghcr.io/project-kratos-lab/kratos-dev:latest"
CONTAINER="kratos_dev"
WS="$HOME/kratos_ws"
GENESIS_VENV="$HOME/kratos_genesis"

# ── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[kratos-dev]${NC} $1"; }
ok()    { echo -e "${GREEN}[  OK  ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[ WARN ]${NC} $1"; }
fail()  { echo -e "${RED}[ FAIL ]${NC} $1" >&2; exit 1; }

# ── Preflight checks ───────────────────────────────────────────────
check_docker() {
    if ! command -v docker &>/dev/null; then
        fail "Docker is not installed.\n       Run ${BOLD}./setup.sh${NC} (Linux) or ${BOLD}./setup_mac.sh${NC} (macOS) first."
    fi

    if docker info &>/dev/null 2>&1; then
        return 0  # all good
    fi

    # Docker exists but "docker info" failed — figure out why
    if [ ! -S /var/run/docker.sock ]; then
        fail "Docker daemon is not running.\n       Run: ${BOLD}sudo systemctl start docker${NC}"
    fi

    # Socket exists but we can't talk to it → permission issue
    if ! grep -q "docker.*$(whoami)\|$(whoami).*docker" /etc/group 2>/dev/null; then
        fail "Your user is not in the 'docker' group.\n       Run: ${BOLD}sudo usermod -aG docker \$(whoami)${NC}\n       Then log out and back in."
    fi

    # Guard against infinite sg re-exec loop
    if [ "${KRATOS_SG_RETRY:-0}" = "1" ]; then
        fail "Docker permission issue persists after group fix.\n       Log out and back in, then try again."
    fi

    # User IS in docker group but this shell hasn't picked it up. Auto-fix.
    warn "Docker group not active in this shell. Re-launching with group..."
    export KRATOS_SG_RETRY=1
    exec sg docker -c "$SCRIPT_PATH $ORIG_ARGS"
}

# ── GPU detection ───────────────────────────────────────────────────
detect_gpu() {
    GPU_FLAGS=""
    if command -v nvidia-smi &>/dev/null; then
        if docker info 2>/dev/null | grep -qi "nvidia"; then
            GPU_FLAGS="--gpus all"
            ok "NVIDIA GPU detected — enabling GPU passthrough"
        else
            warn "NVIDIA GPU found but nvidia-container-toolkit not configured.\n         Continuing without GPU. Run ${BOLD}./setup.sh${NC} to install it."
        fi
    fi
}

# ── Commands ────────────────────────────────────────────────────────
cmd_start() {
    check_docker

    # Check if already running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        warn "Kratos is already running."
        echo ""
        echo -e "  Desktop:   ${BOLD}http://localhost:6080/vnc.html${NC}"
        echo -e "  Rosbridge: ${BOLD}ws://localhost:9090${NC}"
        echo ""
        echo -e "  Run ${BOLD}kratos-env.sh stop${NC} first if you want to restart."
        return 0
    fi

    # Prepare workspace
    mkdir -p "$WS"
    info "Workspace: $WS"

    detect_gpu

    # Check for existing stopped container (preserves installed packages)
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        info "Restarting existing container (your installed packages are preserved)..."
        RUN_OUTPUT=$(docker start "$CONTAINER" 2>&1)
        if [ $? -ne 0 ]; then
            fail "Failed to restart container:\n       $RUN_OUTPUT"
        fi
    else
        info "Creating new container..."
        RUN_OUTPUT=$(docker run -d --name "$CONTAINER" \
            $GPU_FLAGS \
            -e HOST_UID=$(id -u) \
            -e HOST_GID=$(id -g) \
            -p 127.0.0.1:6080:6080 \
            -p 127.0.0.1:9090:9090 \
            -v "$WS":/workspace \
            -v "$SCRIPT_DIR/entrypoint.sh":/entrypoint.sh:ro \
            "$IMAGE" 2>&1)
        if [ $? -ne 0 ]; then
            fail "Failed to start container:\n       $RUN_OUTPUT"
        fi
    fi

    # Wait and verify the container is actually running
    sleep 3
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        LOGS=$(docker logs "$CONTAINER" 2>&1 | tail -10)
        fail "Container crashed on startup:\n$LOGS"
    fi

    ok "Container started"
    echo ""
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║         Kratos Dev Environment Started         ║${NC}"
    echo -e "${GREEN}${BOLD}╠════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  Desktop:   ${BOLD}http://localhost:6080/vnc.html${NC}     ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  Rosbridge: ${BOLD}ws://localhost:9090${NC}                ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  Shell:     ${BOLD}./kratos-env.sh shell${NC}              ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  Stop:      ${BOLD}./kratos-env.sh stop${NC}               ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════╝${NC}"
    echo ""

    # macOS: activate Genesis venv + set ROS_DOMAIN_ID for cross-host comms
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "$GENESIS_VENV" ]; then
            info "macOS detected — activating Genesis venv & setting ROS_DOMAIN_ID=42"
            export ROS_DOMAIN_ID=42
            exec bash --init-file <(cat <<INITEOF
source "$GENESIS_VENV/bin/activate"
export ROS_DOMAIN_ID=42
echo -e "${GREEN}[kratos-dev]${NC} Genesis venv active. ROS_DOMAIN_ID=42"
echo -e "${GREEN}[kratos-dev]${NC} Run ${BOLD}python adapters/genesis_bridge.py${NC} to start the bridge."
PS1='\[\033[0;35m\][kratos-genesis]\[\033[0m\] \w\$ '
INITEOF
            )
        else
            warn "Genesis venv not found at $GENESIS_VENV"
            warn "Run ${BOLD}./setup_mac.sh${NC} to create it."
        fi
    fi
}

cmd_stop() {
    check_docker

    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        warn "Kratos is not running."
        return 0
    fi

    info "Stopping Kratos (your packages and files are preserved)..."
    docker stop "$CONTAINER" >/dev/null 2>&1
    ok "Kratos stopped. Run ${BOLD}./kratos-env.sh start${NC} to resume."
}

cmd_status() {
    check_docker

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        ok "Kratos is ${GREEN}running${NC}"
        echo ""
        echo -e "  Desktop:   ${BOLD}http://localhost:6080/vnc.html${NC}"
        echo -e "  Rosbridge: ${BOLD}ws://localhost:9090${NC}"
        echo ""
        docker ps --filter "name=${CONTAINER}" --format "table {{.Status}}\t{{.Ports}}"
    elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        info "Kratos is ${YELLOW}stopped${NC} (container exists, packages preserved)"
        info "Run ${BOLD}./kratos-env.sh start${NC} to resume."
    else
        info "Kratos is ${YELLOW}not created${NC}"
        info "Run ${BOLD}./kratos-env.sh start${NC} to create and start."
    fi
}

cmd_shell() {
    check_docker

    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        fail "Kratos is not running. Run ${BOLD}./kratos-env.sh start${NC} first."
    fi

    info "Attaching to Kratos shell..."
    docker exec -it "$CONTAINER" gosu kratos bash -c '
        source /opt/ros/humble/setup.bash
        [ -f /workspace/install/setup.bash ] && source /workspace/install/setup.bash
        export TURTLEBOT3_MODEL=waffle
        export HOME=/workspace
        export PS1="\[\033[0;32m\][kratos-dev]\[\033[0m\] \w\$ "
        echo -e "\033[0;32m[kratos-dev]\033[0m ROS2 sourced. You have sudo access (no password)."
        exec bash --norc --noprofile
    '
}

cmd_reset() {
    check_docker

    info "This will ${RED}destroy${NC} the container and all installed packages."
    info "Your workspace files (~/kratos_ws) will NOT be deleted."
    echo ""
    read -p "Are you sure? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Cancelled."
        return 0
    fi

    docker stop "$CONTAINER" 2>/dev/null || true
    docker rm "$CONTAINER" 2>/dev/null || true
    ok "Container removed. Run ${BOLD}./kratos-env.sh start${NC} to create a fresh one."
}

# ── Main ────────────────────────────────────────────────────────────
case "${1:-}" in
    start)  cmd_start  ;;
    stop)   cmd_stop   ;;
    status) cmd_status ;;
    shell)  cmd_shell  ;;
    reset)  cmd_reset  ;;
    *)
        echo ""
        echo -e "${BOLD}Kratos${NC} — ROS2 Humble + Genesis Dev Environment"
        echo ""
        echo -e "  ${BOLD}Usage:${NC}  kratos <command>"
        echo ""
        echo -e "  ${BOLD}Commands:${NC}"
        echo -e "    start    Start the dev container (or resume a stopped one)"
        echo -e "    stop     Stop the container (packages are preserved)"
        echo -e "    status   Check if Kratos is running"
        echo -e "    shell    Open a bash shell inside the container"
        echo -e "    reset    Destroy the container and start fresh"
        echo ""
        ;;
esac

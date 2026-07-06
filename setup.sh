#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${BLUE}[setup]${NC} $1"; }
ok()    { echo -e "${GREEN}[  OK ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[ WARN]${NC} $1"; }
fail()  { echo -e "${RED}[ FAIL]${NC} $1" >&2; exit 1; }
step()  { echo ""; echo -e "${BOLD}── $1 ──${NC}"; }

IMAGE="ghcr.io/project-kratos-lab/kratos-dev:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ "$OSTYPE" == "darwin"* ]] && fail "This is for Linux. Run ${BOLD}./setup_mac.sh${NC} on macOS."

SUDO=""
[ "$(id -u)" -ne 0 ] && { command -v sudo &>/dev/null || fail "Need sudo. Install it or run as root."; SUDO="sudo"; }

# ── Step 1: Docker ──
step "Step 1/4: Docker Engine"
if command -v docker &>/dev/null; then
    ok "Docker already installed ($(docker --version | head -1))"
else
    info "Installing Docker..."
    [ -f /etc/os-release ] && . /etc/os-release || fail "Cannot detect distro. Install Docker manually."
    case "$ID" in
        ubuntu|debian)
            $SUDO apt-get update -qq
            $SUDO apt-get install -y -qq ca-certificates curl gnupg >/dev/null 2>&1
            $SUDO install -m 0755 -d /etc/apt/keyrings
            curl -fsSL "https://download.docker.com/linux/$ID/gpg" | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
            $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $(echo "$VERSION_CODENAME") stable" | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
            $SUDO apt-get update -qq
            $SUDO apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin >/dev/null 2>&1 ;;
        fedora)
            $SUDO dnf -y install dnf-plugins-core >/dev/null 2>&1
            $SUDO dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null
            $SUDO dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin >/dev/null 2>&1 ;;
        arch|manjaro)
            $SUDO pacman -Sy --noconfirm docker >/dev/null 2>&1 ;;
        *) fail "Unsupported distro: $ID. Install Docker manually: https://docs.docker.com/engine/install/" ;;
    esac
    command -v docker &>/dev/null || fail "Docker install failed. See https://docs.docker.com/engine/install/"
    ok "Docker installed"
fi

$SUDO systemctl enable docker --now 2>/dev/null || true
DOCKER="docker"
if ! docker info &>/dev/null 2>&1; then
    if ! groups | grep -q docker; then
        $SUDO usermod -aG docker "$(whoami)"
        warn "Added $(whoami) to docker group. Log out and back in, then re-run."
    fi
    DOCKER="$SUDO docker"
fi

# ── Step 2: NVIDIA GPU ──
step "Step 2/4: NVIDIA GPU Support"
if command -v nvidia-smi &>/dev/null; then
    ok "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
    if ! $DOCKER info 2>/dev/null | grep -qi nvidia; then
        info "Installing NVIDIA Container Toolkit..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | $SUDO gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null
        curl -fsSL "https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list" | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | $SUDO tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
        $SUDO apt-get update -qq 2>/dev/null && $SUDO apt-get install -y -qq nvidia-container-toolkit >/dev/null 2>&1
        $SUDO nvidia-ctk runtime configure --runtime=docker >/dev/null 2>&1
        $SUDO systemctl restart docker 2>/dev/null
        ok "NVIDIA Container Toolkit installed"
    else
        ok "NVIDIA Container Toolkit already configured"
    fi
else
    info "No NVIDIA GPU — Gazebo will use software rendering (still works)"
fi

# ── Step 3: Pull image ──
step "Step 3/4: Container Image"
info "Pulling $IMAGE (may take a while, ~4-6 GB)..."
$DOCKER pull "$IMAGE" || fail "Failed to pull image. Check internet or build locally: docker build -t $IMAGE ."
ok "Image ready"

# ── Step 4: Install CLI ──
step "Step 4/4: Install CLI"
$SUDO cp "$SCRIPT_DIR/kratos" /usr/local/bin/kratos && $SUDO chmod +x /usr/local/bin/kratos
ok "kratos CLI installed to /usr/local/bin/kratos"

echo ""
echo -e "${GREEN}${BOLD}  Setup complete ✓  Run: kratos start${NC}"
echo ""

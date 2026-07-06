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
GENESIS_VENV="$HOME/kratos_genesis"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ "$OSTYPE" != "darwin"* ]] && fail "This is for macOS. Run ${BOLD}./setup.sh${NC} on Linux."

# ── Step 1: Homebrew ──
step "Step 1/5: Homebrew"
if command -v brew &>/dev/null; then
    ok "Homebrew installed"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to path for Apple Silicon
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    command -v brew &>/dev/null || fail "Homebrew install failed. See https://brew.sh"
    ok "Homebrew installed"
fi

# ── Step 2: Docker Desktop ──
step "Step 2/5: Docker Desktop"
if command -v docker &>/dev/null; then
    ok "Docker already installed"
else
    info "Installing Docker Desktop via Homebrew..."
    brew install --cask docker
    info "Opening Docker Desktop (first launch takes a moment)..."
    open -a Docker
    info "Waiting for Docker daemon to start..."
    for i in $(seq 1 30); do
        docker info &>/dev/null 2>&1 && break
        sleep 2
    done
    docker info &>/dev/null 2>&1 || fail "Docker daemon didn't start. Open Docker Desktop manually, then re-run."
    ok "Docker Desktop ready"
fi

# ── Step 3: Python venv + Genesis deps ──
step "Step 3/5: Genesis Virtual Environment"
PYTHON=""
for p in python3.11 python3.10 python3; do
    command -v "$p" &>/dev/null && { PYTHON="$p"; break; }
done
[ -z "$PYTHON" ] && fail "Python 3 not found. Install: ${BOLD}brew install python@3.11${NC}"
ok "Using $($PYTHON --version)"

if [ -d "$GENESIS_VENV" ]; then
    ok "Venv already exists at $GENESIS_VENV"
else
    info "Creating venv at $GENESIS_VENV ..."
    $PYTHON -m venv "$GENESIS_VENV"
    ok "Venv created"
fi

info "Installing Genesis + ROS bridge deps (this may take a while)..."
source "$GENESIS_VENV/bin/activate"
pip install --upgrade pip >/dev/null 2>&1
pip install roslibpy genesis-world torch torchvision 2>&1 | while IFS= read -r line; do
    echo -ne "\r${BLUE}[setup]${NC} pip: installing...  "
done
echo ""
ok "Python packages installed in $GENESIS_VENV"

# ── Step 4: Pull image ──
step "Step 4/5: Container Image"
info "Pulling $IMAGE (may take a while, ~4-6 GB)..."
docker pull "$IMAGE" || fail "Failed to pull image. Check internet."
ok "Image ready"

# ── Step 5: Install CLI ──
step "Step 5/5: Install CLI"
sudo cp "$SCRIPT_DIR/kratos" /usr/local/bin/kratos && sudo chmod +x /usr/local/bin/kratos
ok "kratos CLI installed"

echo ""
echo -e "${GREEN}${BOLD}  Setup complete ✓  Run: kratos start${NC}"
echo ""
echo -e "  The Genesis venv is at: ${BOLD}$GENESIS_VENV${NC}"
echo -e "  It activates automatically when you run ${BOLD}kratos start${NC} on macOS."
echo ""

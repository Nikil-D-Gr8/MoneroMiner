#!/bin/bash
set -e

# =====================================================
# Monero Mining Bootstrap Script (xmrig + tmux)
# =====================================================

SESSION_NAME="monero-miner"
XMRIG_REPO="https://github.com/xmrig/xmrig.git"
XMRIG_DIR="$HOME/xmrig"
BUILD_DIR="$XMRIG_DIR/build"
XMRIG_BIN="$BUILD_DIR/xmrig"

POOL="pool.supportxmr.com:3333"
WALLET="84Vf1hBvJkPFE3MnGUcM5A6R4xnXySvSRjicT1NwTj84eqQWvBbwS2pDvoDzNgeChJGcem2VRGCZnS2PaeC7PmBzBgY5LzX"

CPU_THREADS_HINT=60
CPU_PRIORITY=3
HUGEPAGES=1280

# =====================================================
# Helper functions
# =====================================================

info() {
  echo -e "\n[INFO] $1"
}

error() {
  echo -e "\n[ERROR] $1"
  exit 1
}

# =====================================================
# Detect distro
# =====================================================

source /etc/os-release

install_dependencies() {

  if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
    info "Detected Debian/Ubuntu"

    sudo apt update
    sudo apt install -y \
      git \
      cmake \
      build-essential \
      libssl-dev \
      libhwloc-dev \
      hwloc \
      tmux

  elif [[ "$ID" == "fedora" || "$ID_LIKE" == *"rhel"* ]]; then
    info "Detected Fedora/RHEL"

    sudo dnf install -y \
      git \
      make \
      cmake \
      gcc \
      gcc-c++ \
      libstdc++-static \
      libuv-static \
      hwloc-devel \
      openssl-devel \
      tmux

  else
    error "Unsupported distribution: $ID"
  fi
}

# =====================================================
# 1. Install dependencies
# =====================================================

install_dependencies

# =====================================================
# 2. Kernel tuning
# =====================================================

info "Configuring kernel tuning (MSR + huge pages)"

if [ ! -f /etc/modules-load.d/msr.conf ]; then
  echo "msr" | sudo tee /etc/modules-load.d/msr.conf
fi

sudo modprobe msr || true

SYSCTL_FILE="/etc/sysctl.d/99-xmrig.conf"

sudo tee "$SYSCTL_FILE" >/dev/null <<EOF
kernel.perf_event_paranoid=1
vm.nr_hugepages=$HUGEPAGES
EOF

sudo sysctl --system >/dev/null

# =====================================================
# 3. Clone xmrig
# =====================================================

if [ ! -d "$XMRIG_DIR" ]; then
  info "Cloning xmrig repository"
  git clone "$XMRIG_REPO" "$XMRIG_DIR"
else
  info "xmrig repository already exists"
fi

# =====================================================
# 4. Build xmrig
# =====================================================

if [ ! -x "$XMRIG_BIN" ]; then
  info "Building xmrig"

  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"

  cmake ..
  make -j"$(nproc)"

else
  info "xmrig already built — skipping build"
fi

# =====================================================
# 5. Start miner in tmux
# =====================================================

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  info "Miner already running in tmux session '$SESSION_NAME'"
  echo "Attach with: tmux attach -t $SESSION_NAME"
  exit 0
fi

info "Starting xmrig in tmux session '$SESSION_NAME'"

tmux new-session -d -s "$SESSION_NAME" bash -c "
  cd \"$BUILD_DIR\" || exit 1

  echo \"[INFO] Monero miner started\"
  echo \"[INFO] Pool   : $POOL\"
  echo \"[INFO] Wallet : ${WALLET:0:6}...${WALLET: -6}\"
  echo \"----------------------------------------\"

  ./xmrig \
    -o \"$POOL\" \
    -u \"$WALLET\" \
    -p laptop \
    --cpu-max-threads-hint=$CPU_THREADS_HINT \
    --cpu-priority=$CPU_PRIORITY \
    --donate-level=0 \
    --randomx-no-rdmsr

  exec bash
"

info "Mining started successfully"
echo "Attach anytime with: tmux attach -t $SESSION_NAME"

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
# 1. Install system dependencies
# =====================================================

info "Installing system dependencies (if needed)"

sudo apt update
sudo apt install -y \
  git \
  cmake \
  build-essential \
  libssl-dev \
  libhwloc-dev \
  hwloc \
  tmux

# =====================================================
# 2. Kernel tuning (persistent)
# =====================================================

info "Configuring kernel tuning (MSR + huge pages)"

# Load MSR module at boot
if [ ! -f /etc/modules-load.d/msr.conf ]; then
  echo "msr" | sudo tee /etc/modules-load.d/msr.conf
fi

sudo modprobe msr || true

# Sysctl settings
SYSCTL_FILE="/etc/sysctl.d/99-xmrig.conf"

sudo tee "$SYSCTL_FILE" >/dev/null <<EOF
kernel.perf_event_paranoid=1
vm.nr_hugepages=$HUGEPAGES
EOF

sudo sysctl --system >/dev/null

# =====================================================
# 3. Clone xmrig (only once)
# =====================================================

if [ ! -d "$XMRIG_DIR" ]; then
  info "Cloning xmrig repository"
  git clone "$XMRIG_REPO" "$XMRIG_DIR"
else
  info "xmrig repository already exists"
fi

# =====================================================
# 4. Build xmrig (only once)
# =====================================================

if [ ! -x "$XMRIG_BIN" ]; then
  info "Building xmrig (first time only)"

  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"

  cmake ..
  make -j"$(nproc)"

else
  info "xmrig already built — skipping build"
fi

# =====================================================
# 5. Start mining in tmux
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

  echo
  echo \"[INFO] xmrig exited. Press Ctrl+D to close tmux.\"
  exec bash
"

info "Mining started successfully"
echo "Attach anytime with: tmux attach -t $SESSION_NAME"


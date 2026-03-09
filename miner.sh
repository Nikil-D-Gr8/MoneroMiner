#!/bin/bash

# ---------------------------------------
# Monero Miner (xmrig via tmux - hardened)
# ---------------------------------------

SESSION_NAME="monero-miner"
XMRIG_DIR="$HOME/xmrig/build"
XMRIG_BIN="$XMRIG_DIR/xmrig"

WALLET="84Vf1hBvJkPFE3MnGUcM5A6R4xnXySvSRjicT1NwTj84eqQWvBbwS2pDvoDzNgeChJGcem2VRGCZnS2PaeC7PmBzBgY5LzX"
POOL="pool.supportxmr.com:3333"

CPU_THREADS_HINT=90
CPU_PRIORITY=3

# -----------------------
# Safety checks
# -----------------------

if ! command -v tmux >/dev/null 2>&1; then
  echo "ERROR: tmux is not installed."
  exit 1
fi

if [ ! -x "$XMRIG_BIN" ]; then
  echo "ERROR: xmrig binary not found at $XMRIG_BIN"
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is not installed."
  exit 1
fi

# -----------------------
# Prevent duplicate miners
# -----------------------

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Miner already running in tmux session '$SESSION_NAME'"
  echo "Attach with: tmux attach -t $SESSION_NAME"
  exit 0
fi

echo "Starting Monero miner in tmux session: $SESSION_NAME"

# -----------------------
# Start tmux session
# -----------------------

tmux new-session -d -s "$SESSION_NAME" bash -c "
  cd \"$XMRIG_DIR\" || exit 1

  echo \"[INFO] Starting xmrig...\"
  echo \"[INFO] Pool   : $POOL\"
  echo \"[INFO] Wallet : ${WALLET:0:6}...${WALLET: -6}\"
  echo \"----------------------------------------\"

  sudo ./xmrig \
    -o \"$POOL\" \
    -u \"$WALLET\" \
    -p laptop \
    --cpu-max-threads-hint=$CPU_THREADS_HINT \
    --cpu-priority=$CPU_PRIORITY \
    --donate-level=0

  echo
  echo \"[INFO] xmrig exited. Press Ctrl+D to close tmux session.\"
  exec bash
"

echo "Miner started successfully."
echo "Attach with: tmux attach -t $SESSION_NAME"

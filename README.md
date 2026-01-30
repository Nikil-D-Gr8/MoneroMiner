# MoneroMiner

Bootstrap script to build and run `xmrig` in a `tmux` session.

## Requirements

- Linux with `apt` (Debian/Ubuntu-based)
- `sudo` access
- Internet access to clone/build `xmrig`

The script installs dependencies and applies kernel tuning (huge pages + MSR).

## Quick Start

1. Open `miner.sh` and set your wallet and pool:
   - `WALLET`
   - `POOL`
2. Make the script executable and run it:

```bash
chmod +x ./miner.sh
./miner.sh
```

3. Attach to the miner session:

```bash
tmux attach -t monero-miner
```

Detach from `tmux` with `Ctrl+b`, then `d`.

## Configuration

Edit these variables in `miner.sh` as needed:

- `POOL`: Mining pool host:port
- `WALLET`: Your Monero address
- `CPU_THREADS_HINT`: Percent of CPU threads to use (0–100)
- `CPU_PRIORITY`: Process priority (0–5)
- `HUGEPAGES`: Huge pages count

## What the Script Does

1. Installs build/runtime dependencies with `apt`
2. Enables MSR module and configures huge pages
3. Clones `xmrig` (if missing)
4. Builds `xmrig` (if missing)
5. Starts mining in a detached `tmux` session

## Stop Mining

Attach and stop `xmrig` with `Ctrl+C`:

```bash
tmux attach -t monero-miner
```

Then close the session:

```bash
tmux kill-session -t monero-miner
```

## Troubleshooting

- If `tmux` says the session exists, it’s already running.
- If huge pages can’t be allocated, lower `HUGEPAGES`.
- If build fails, re-run after installing missing packages.

## Notes

- This script runs `xmrig` with `--donate-level=0`.
- Use responsibly and ensure you have permission to mine on the machine.# MoneroMiner

# MoneroMiner

Bootstrap script to build and run `xmrig` inside a `tmux` session.

The script automatically installs dependencies, configures kernel parameters required by RandomX, builds `xmrig`, and launches the miner in a detached `tmux` session.

---

## Supported Systems

* Debian / Ubuntu (uses `apt`)
* Fedora / RHEL-based distributions (uses `dnf`)

Requirements:

* Linux system with `sudo`
* Internet access (to clone and build `xmrig`)
* A valid Monero wallet address

---

## Quick Start

1. Open `miner.sh` and configure your mining settings:

* `WALLET` – your Monero wallet address
* `POOL` – mining pool host and port

2. Make the script executable:

```bash
chmod +x miner.sh
```

3. Run the script:

```bash
./miner.sh
```

---

## Viewing the Miner

The miner runs inside a `tmux` session named:

```
monero-miner
```

Attach to it with:

```bash
tmux attach -t monero-miner
```

To detach without stopping the miner:

```
Ctrl + b
d
```

---

## Configuration

The following variables can be adjusted in `miner.sh`:

| Variable           | Description                              |
| ------------------ | ---------------------------------------- |
| `POOL`             | Mining pool host and port                |
| `WALLET`           | Your Monero wallet address               |
| `CPU_THREADS_HINT` | Percentage of CPU threads to use (0–100) |
| `CPU_PRIORITY`     | Process priority (0–5)                   |
| `HUGEPAGES`        | Number of huge pages to allocate         |

---

## What the Script Does

1. Detects the Linux distribution (`apt` or `dnf`)
2. Installs required build and runtime dependencies
3. Enables the `msr` kernel module
4. Configures huge pages for RandomX
5. Clones the `xmrig` repository if not already present
6. Builds `xmrig` from source
7. Launches the miner inside a detached `tmux` session

---

## Stopping the Miner

Attach to the session:

```bash
tmux attach -t monero-miner
```

Stop the miner with:

```
Ctrl + C
```

Then terminate the session:

```bash
tmux kill-session -t monero-miner
```

---

## Troubleshooting

**tmux session already exists**

The miner is already running. Attach using:

```bash
tmux attach -t monero-miner
```

**Huge pages allocation fails**

Reduce the `HUGEPAGES` value in `miner.sh`.

**Build errors**

Ensure required packages installed correctly. Re-run the script after resolving dependency issues.

---

## Notes

* The script builds `xmrig` locally from source.
* `xmrig` runs with `--donate-level=0`.
* Only run mining workloads on machines where you have permission to do so.

---

## Project Structure

```
.
├── miner.sh
└── README.md
```

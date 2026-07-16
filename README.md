# wireguard

Docker-based WireGuard VPN server (linuxserver/wireguard).

## Prerequisites

- Linux host (kernel with `wireguard` module available)
- Docker + docker compose plugin
- nftables (`nft`)
- **`inet host_fw input` chain must exist** — host firewall framework. If missing, create it once:
  ```bash
  sudo nft add table inet host_fw
  sudo nft 'add chain inet host_fw input { type filter hook input priority 0; policy accept; }'
  ```
  To persist across reboots:
  ```bash
  sudo nft list ruleset | sudo tee /etc/nftables.conf >/dev/null
  sudo systemctl enable --now nftables
  ```

## Setup

```bash
cp .env.example .env
# Edit .env: set WG_SERVERURL to your public IP/domain
sudo bash ./init.sh
```

After startup, client configs are at `./config/peer*/peer*.conf` or `./config/peer*/peer*.png` (QR).

## Operations

| Command | Action |
|---|---|
| `sudo bash ./init.sh` | First-time setup: load kernel module + nftables rules + start container |
| `sudo bash ./up.sh` | Start container only |
| `sudo bash ./down.sh` | Stop container + remove nftables rules |
| `bash ./peer.sh list` | List all peers |
| `bash ./peer.sh show <n>` | Print peer n's .conf contents |
| `bash ./peer.sh export <n> [dir]` | Copy peer n's .conf (and QR) to target directory |

## Environment Variables (.env)

| Key | Description |
|---|---|
| `WG_SERVERURL` | Server public IP/domain for clients to connect to |
| `WG_SERVERPORT` | UDP port (applied to host, container, and firewall rules) |
| `WG_PEERS` | Initial number of peers to create |
| `WG_PEERDNS` | DNS servers for peers (explicitly set for iOS) |
| `WG_INTERNAL_SUBNET` | WireGuard internal subnet (e.g. `10.8.0.0`) |
| `WG_ALLOWEDIPS` | Full tunnel `0.0.0.0/0,::/0` / split tunnel with partial ranges |
| `WG_KEEPALIVE` | Persistent keepalive in seconds for NAT stability (mobile recommended) |

## Adding Peers

Increase `WG_PEERS` in `.env` and restart the container:

```bash
sudo bash ./down.sh
sudo bash ./init.sh
```

## Extracting Peer Configs

Use `peer.sh` to view/export peer config files (no sudo needed):

```bash
# List all peers
bash ./peer.sh list

# Print peer1's .conf to terminal
bash ./peer.sh show 1

# Show peer1's QR image path
bash ./peer.sh qr 1

# Copy peer1's .conf + QR to ~/Downloads
bash ./peer.sh export 1 ~/Downloads
```

## Troubleshooting

- `Error: No such file or directory ... inet host_fw input` — Run the host_fw chain creation commands from *Prerequisites* above.
- Client handshakes but no traffic flows — Check `WG_ALLOWEDIPS`, `net.ipv4.ip_forward`, and host NAT/masquerading.
- Mobile disconnects frequently — Keep `WG_KEEPALIVE=25`.

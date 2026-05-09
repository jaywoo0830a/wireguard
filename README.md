# wireguard

Docker 기반 WireGuard VPN 서버 (linuxserver/wireguard).

## 사전 요건

- Linux 호스트 (커널에 `wireguard` 모듈 가용)
- Docker + docker compose plugin
- nftables(`nft`)
- **`inet host_fw input` 체인이 미리 존재해야 함** — 호스트 방화벽 프레임워크. 없으면 한 번만 생성:
  ```bash
  sudo nft add table inet host_fw
  sudo nft 'add chain inet host_fw input { type filter hook input priority 0; policy accept; }'
  ```
  재부팅 후에도 유지하려면:
  ```bash
  sudo nft list ruleset | sudo tee /etc/nftables.conf >/dev/null
  sudo systemctl enable --now nftables
  ```

## 셋업

```bash
cp .env.example .env
# .env 편집: WG_SERVERURL을 본인 공인 IP/도메인으로 설정
sudo bash ./init.sh
```

기동 후 클라이언트 설정은 `./config/peer*/peer*.conf` 또는 `./config/peer*/peer*.png`(QR).

## 운영

| 명령 | 동작 |
|---|---|
| `sudo bash ./init.sh` | 최초 기동: 커널 모듈 로드 + nftables 룰 추가 + 컨테이너 기동 |
| `sudo bash ./up.sh` | 컨테이너만 기동 |
| `sudo bash ./down.sh` | 컨테이너 정지 + nftables 룰 제거 |

## 환경 변수 (.env)

| 키 | 의미 |
|---|---|
| `WG_SERVERURL` | 클라이언트가 접속할 서버 공인 IP/도메인 |
| `WG_SERVERPORT` | UDP 포트 (호스트·컨테이너·방화벽 룰 모두에 적용됨) |
| `WG_PEERS` | 최초 생성할 피어 수 |
| `WG_PEERDNS` | 피어가 사용할 DNS (iOS는 명시 권장) |
| `WG_INTERNAL_SUBNET` | WireGuard 내부 대역 (예: `10.8.0.0`) |
| `WG_ALLOWEDIPS` | 풀터널 `0.0.0.0/0,::/0` / 스플릿터널은 부분 대역 |
| `WG_KEEPALIVE` | NAT 안정성용 keepalive 초 (모바일 권장) |

## 피어 추가

`.env`의 `WG_PEERS`를 늘리고 컨테이너 재기동:

```bash
sudo bash ./down.sh
sudo bash ./init.sh
```

## 트러블슈팅

- `Error: No such file or directory ... inet host_fw input` — 위 *사전 요건*의 host_fw 체인 생성 명령 실행.
- 클라이언트가 핸드셰이크는 되지만 트래픽이 안 흐름 — `WG_ALLOWEDIPS`, `net.ipv4.ip_forward`, 호스트 NAT/마스커레이딩 확인.
- 모바일에서 자주 끊김 — `WG_KEEPALIVE=25` 유지.

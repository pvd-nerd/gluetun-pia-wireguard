# Gluetun PIA WireGuard Configuration Generator

Automated WireGuard VPN configuration generation using [Private Internet Access (PIA) manual connection scripts](https://github.com/pia-foss/manual-connections) to use with Gluetun.

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/pvd-nerd/gluetun-pia-wireguard.git
   cd gluetun-pia-wireguard
   ```

2. **Edit `docker-compose.yml` with your PIA credentials**
   ```bash
   nano docker-compose.yml
   ```
   Update these values in the `gluetun-pia-wireguard` service:
   ```yaml
   environment:
     PIA_USER: your_username_here
     PIA_PASS: your_password_here
   ```

3. **Start the containers**
   ```bash
   docker compose up -d
   ```

4. **Verify VPN connection**
   ```bash
   docker compose exec gluetun wget -qO- https://ipinfo.io/json
   ```

## Configuration

### Required Environment Variables

- `PIA_USER` - Your PIA username (required)
- `PIA_PASS` - Your PIA password (required)
- `PREFERRED_REGION` - WireGuard server region (default: `us_new_york_city`)
- `VPN_PROTOCOL` - Always `wireguard` (required)
- `CONFIG_OUTPUT_PATH` - Always `/app/config/wg0.conf` (required)

### Docker Volumes

- `pia-config` - Stores generated WireGuard configuration to be used by Gluetun.
- `gluetun-data` - Stores Gluetun container persistent data

### Docker Compose

   ```yaml
---


services:
 gluetun-pia-wireguard:
  image: pvdnerd/gluetun-pia-wireguard
  container_name: gluetun-pia-wireguard
  restart: no
  environment:
      PIA_USER: piausername
      PIA_PASS: piapasssword
      PREFERRED_REGION: us_new_york_city
      VPN_PROTOCOL: wireguard
      CONFIG_OUTPUT_PATH: /app/config/wg0.conf
    volumes:
      - pia-config:/app/config

 gluetun:
  image: qmcgaw/gluetun
  container_name: gluetun
  restart: always
  cap_add:
      - NET_ADMIN
  devices:
      - /dev/net/tun:/dev/net/tun
  environment:
      VPN_SERVICE_PROVIDER: custom
      VPN_TYPE: wireguard
      UPDATER_PERIOD: 24h
      TZ: Etc/UTC
      FIREWALL_OUTBOUND_SUBNETS: 172.16.0.0/12
    volumes:
      - gluetun-data:/gluetun
      - pia-config:/gluetun/wireguard:ro
    depends_on:
      gluetun-pia-wireguard:
        condition: service_completed_successfully

volumes:
  pia-config:
  gluetun-data:
   ```

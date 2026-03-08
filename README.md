# Gluetun PIA WireGuard

Automated WireGuard VPN configuration generation using Private Internet Access (PIA) with Gluetun.

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

- `pia-config` - Stores generated WireGuard configuration
- `gluetun-data` - Stores Gluetun state and DNS data

## Services

### gluetun-pia-wireguard
- Pulls pre-built image: `pvd-nerd/gluetun-pia-wireguard`
- Generates WireGuard config from PIA API
- Runs once and exits
- Waits for completion before gluetun starts

### gluetun
- Pulls official image: `qmcgaw/gluetun`
- VPN tunnel container
- Always running with auto-restart
- Depends on `gluetun-pia-wireguard` to complete successfully
#!/bin/bash

set -e

# Configuration from environment variables
PIA_USER="${PIA_USER:-}"
PIA_PASS="${PIA_PASS:-}"
PREFERRED_REGION="${PREFERRED_REGION:-us_new_york}"
VPN_PROTOCOL="${VPN_PROTOCOL:-wireguard}"
PIA_DNS="${PIA_DNS:-true}"
PIA_PF="${PIA_PF:-false}"
DISABLE_IPV6="${DISABLE_IPV6:-no}"
CONFIG_OUTPUT_PATH="${CONFIG_OUTPUT_PATH:-/app/config/wg0.conf}"

# Validate required variables
if [ -z "$PIA_USER" ] || [ -z "$PIA_PASS" ]; then
    echo "Error: PIA_USER and PIA_PASS environment variables are required"
    exit 1
fi

echo "Generating PIA WireGuard configuration..."
echo "Region: $PREFERRED_REGION"
echo "DNS: $PIA_DNS"
echo "Port Forwarding: $PIA_PF"

# Create config directory
mkdir -p "$(dirname "$CONFIG_OUTPUT_PATH")"

# Run PIA manual connection script
# The script outputs the config, so we capture it
export PIA_USER
export PIA_PASS
export PREFERRED_REGION
export VPN_PROTOCOL
export PIA_DNS
export PIA_PF
export DISABLE_IPV6

cd /pia-manual

if [ "$VPN_PROTOCOL" = "wireguard" ]; then
    echo "Getting authentication token..."

    # First, get the authentication token
    bash get_token.sh > /tmp/token_output.txt 2>&1
    # Extract the PIA_TOKEN
    PIA_TOKEN=$(grep "^PIA_TOKEN=" /tmp/token_output.txt | cut -d= -f2-)
    export PIA_TOKEN

    if [ -z "$PIA_TOKEN" ]; then
        echo "Error: Failed to obtain PIA token"
        cat /tmp/token_output.txt
        exit 1
    fi

    echo "✓ Got authentication token"

    echo "Getting region information..."

    # Then get the region and server information
    set +e
    bash get_region.sh > /tmp/region_output.txt 2>&1
    REGION_EXIT=$?
    set -e

    if [ $REGION_EXIT -ne 0 ]; then
        echo "Error: get_region.sh exited with code $REGION_EXIT"
        echo "Output:"
        cat /tmp/region_output.txt
        exit 1
    fi

    # Extract the specific variables we need (they may not be at line start)
    WG_SERVER_IP=$(grep -oP 'WG_SERVER_IP=\K[^ ]+' /tmp/region_output.txt | head -1)
    WG_HOSTNAME=$(grep -oP 'WG_HOSTNAME=\K[^ ]+' /tmp/region_output.txt | head -1)
    export WG_SERVER_IP WG_HOSTNAME

    if [ -z "$WG_SERVER_IP" ] || [ -z "$WG_HOSTNAME" ]; then
        echo "Error: Failed to obtain region information"
        echo "Region output:"
        cat /tmp/region_output.txt
        echo ""
        echo "Extracted: WG_SERVER_IP=$WG_SERVER_IP, WG_HOSTNAME=$WG_HOSTNAME"
        exit 1
    fi

    echo "✓ Got WireGuard server: $WG_HOSTNAME ($WG_SERVER_IP)"

    # Export variables for the config generation script
    export WG_SERVER_IP
    export WG_HOSTNAME
    export PIA_TOKEN
    export PIA_DNS
    export PIA_PF

    echo "Generating WireGuard configuration..."

    # Now generate the config without connecting
    export PIA_CONNECT=false

    # Run config generation script
    set +e
    bash connect_to_wireguard_with_token.sh > /tmp/config_script_output.txt 2>&1
    CONFIG_EXIT=$?
    set -e

    if [ $CONFIG_EXIT -ne 0 ]; then
        echo "Error generating WireGuard config (exit code: $CONFIG_EXIT)"
        echo "Output:"
        cat /tmp/config_script_output.txt
        exit 1
    fi

    # Copy the generated config from /etc/wireguard/pia.conf to output path
    if [ -f /etc/wireguard/pia.conf ]; then
        cp /etc/wireguard/pia.conf "$CONFIG_OUTPUT_PATH"
    else
        echo "Error: WireGuard config file not created at /etc/wireguard/pia.conf"
        echo "Script output:"
        cat /tmp/config_script_output.txt
        exit 1
    fi

    # Cleanup temp files
    rm -f /tmp/token_output.txt /tmp/region_output.txt /tmp/config_script_output.txt
else
    echo "Error: Only wireguard protocol is currently supported in this container"
    exit 1
fi

# Verify config was created
if [ ! -s "$CONFIG_OUTPUT_PATH" ]; then
    echo "Error: Failed to generate WireGuard configuration"
    exit 1
fi

echo "✓ WireGuard configuration generated successfully"
echo "✓ Config saved to: $CONFIG_OUTPUT_PATH"
echo ""
echo "Configuration file contents (first 10 lines):"
head -10 "$CONFIG_OUTPUT_PATH"

# If container is interactive, keep it running
# Otherwise exit after generating config
if [ -t 0 ]; then
    echo ""
    echo "Config generation complete. Container will exit."
fi

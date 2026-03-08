FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    wireguard-tools \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone PIA manual connections script
RUN git clone https://github.com/pia-foss/manual-connections.git /pia-manual

# Create working directory for configs
WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create volume for output configs
VOLUME ["/app/config"]

ENTRYPOINT ["/entrypoint.sh"]

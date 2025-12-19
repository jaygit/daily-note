FROM python:3.11-slim

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates git rsync curl procps build-essential \
    gcc make libffi-dev libssl-dev python3-dev && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /opt/daily-note

# Copy project into image
COPY . /opt/daily-note

# Default vault mount point (container expects host to mount vault at /vault)
ENV VAULT_MOUNT=/vault
# Install into the vault mount so installed tree lives under the vault (user requested)
ENV XDG_DATA_HOME=/vault
ENV XDG_BIN_HOME=/usr/local/bin

# Ensure scripts are executable
RUN chmod -R +x /opt/daily-note/scripts || true

# Run the installer non-interactively targeting the mounted vault (if present)
RUN /opt/daily-note/install.sh --vault-path "$VAULT_MOUNT" --yes || true

WORKDIR /opt/daily-note

# Install MCP server dependencies
RUN pip install --no-cache-dir fastapi uvicorn

EXPOSE 8000

CMD ["/bin/bash", "-lc", "uvicorn mcp_server.app:app --host 0.0.0.0 --port 8000"]

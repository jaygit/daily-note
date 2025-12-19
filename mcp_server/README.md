# obs MCP server — Quickstart

This folder contains a minimal FastAPI-based MCP server that runs the `obs` helper inside a container and exposes a small HTTP API.

Quick start (with docker-compose)

1. Ensure you have a host vault directory next to the repo, for example:

```bash
mkdir -p ./vault
# populate ./vault with some markdown files or leave empty
```

2. Build and start the service:

```bash
docker-compose up --build -d
```

3. Health check:

```bash
curl -s http://localhost:8000/health
# -> {"status":"ok"}
```

Run `obs` via the MCP server

- Example: get installed version

```bash
curl -s -X POST http://localhost:8000/run \
  -H 'Content-Type: application/json' \
  -d '{"args": ["-v"], "timeout": 10}'
```

- Example: run operation `search` (non-interactive; may require additional args)

```bash
curl -s -X POST http://localhost:8000/run \
  -H 'Content-Type: application/json' \
  -d '{"args": ["-o","search"], "timeout": 30}'
```

Python client example

See `client_example.py` for a minimal example using `requests`.

Security note

This server executes commands on the host container. Do not expose it to untrusted networks. For production consider:

- Authentication (API keys / TLS)
- Input validation / operation allow-list
- Running a non-root user inside the container

Troubleshooting

- If commands return "obs executable not found", ensure the installer placed the `obs` shim under `/usr/local/bin/obs` or the expected script path inside the container. You can exec into the container to inspect files:

```bash
docker exec -it obs-mcp /bin/bash
ls -la /vault /usr/local/bin /opt/daily-note/scripts
```

Feedback

If you want a client library, ACLs, or example CI integration, I can add those next.

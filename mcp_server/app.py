from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess
import shlex
import os

app = FastAPI(title="obs-mcp-server")

class CmdRequest(BaseModel):
    args: list[str]
    timeout: int | None = 30

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/run")
async def run_cmd(req: CmdRequest):
    # Resolve obs binary path; prefer XDG-installed shim (/usr/local/bin/obs) or /vault/daily-note/scripts/main.sh
    obs_candidates = ["/usr/local/bin/obs", "/vault/daily-note/scripts/main.sh", "/opt/daily-note/scripts/main.sh"]
    obs_path = None
    for c in obs_candidates:
        if os.path.isfile(c) and os.access(c, os.X_OK):
            obs_path = c
            break
    if obs_path is None:
        raise HTTPException(status_code=500, detail="obs executable not found in container")

    cmd = [obs_path] + req.args
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=req.timeout, check=False)
        return {
            "returncode": proc.returncode,
            "stdout": proc.stdout.decode(errors="replace"),
            "stderr": proc.stderr.decode(errors="replace"),
        }
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="Command timed out")

*** End Patch
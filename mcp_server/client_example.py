#!/usr/bin/env python3
"""Minimal client example for the obs MCP server."""
import requests
import sys

API_URL = "http://localhost:8000/run"

def run_obs(args, timeout=30):
    payload = {"args": args, "timeout": timeout}
    r = requests.post(API_URL, json=payload, timeout=timeout+5)
    r.raise_for_status()
    return r.json()

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: client_example.py -v | -o search ...")
        sys.exit(2)
    args = sys.argv[1:]
    resp = run_obs(args)
    print("returncode:", resp.get("returncode"))
    print("stdout:\n", resp.get("stdout"))
    print("stderr:\n", resp.get("stderr"))

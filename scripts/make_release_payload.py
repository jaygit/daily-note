#!/usr/bin/env python3
import json

with open('RELEASE_NOTES/v.1.0.0.md', 'r', encoding='utf-8') as f:
    note = f.read()

payload = {
    "tag_name": "v.1.0.0",
    "title": "v.1.0.0",
    "note": note
}
print(json.dumps(payload))

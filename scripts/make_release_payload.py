#!/usr/bin/env python3
import json
import glob
import os
import re

# Determine version: prefer env VAR VERSION, else pick latest RELEASE_NOTES/v.*.md
version = os.environ.get('VERSION')
if not version:
    files = glob.glob('RELEASE_NOTES/v.*.md')
    if files:
        # sort by numeric components
        def ver_key(p):
            m = re.search(r'v(\d+)\.(\d+)\.(\d+)', p)
            return tuple(int(x) for x in m.groups()) if m else (0,0,0)
        files.sort(key=ver_key)
        chosen = files[-1]
        version = os.path.splitext(os.path.basename(chosen))[0]
    else:
        version = os.environ.get('GIT_TAG', 'v.0.0.0')

note_file = f'RELEASE_NOTES/{version}.md'
if not os.path.exists(note_file):
    # fallback to any release note
    files = glob.glob('RELEASE_NOTES/*.md')
    note_file = files[-1] if files else ''

note = ''
if note_file and os.path.exists(note_file):
    with open(note_file, 'r', encoding='utf-8') as f:
        note = f.read()

payload = {
    "tag_name": version,
    "title": version,
    "note": note
}
print(json.dumps(payload))

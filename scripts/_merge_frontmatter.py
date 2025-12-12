#!/usr/bin/env python3
"""
Merge project and tags into the YAML frontmatter of a Markdown file.
Usage: _merge_frontmatter.py <file> <project> <project_tag> [extra_tag]

This script requires PyYAML (`pip install pyyaml`). If PyYAML is not
available it will exit with a helpful message.
"""
import sys
from pathlib import Path
#!/usr/bin/env python3
"""
Merge project and tags into the YAML frontmatter of a Markdown file.
Usage: _merge_frontmatter.py <file> <project> <project_tag> [extra_tag]

This script requires PyYAML (`pip install pyyaml`). If PyYAML is not
available it will exit with a helpful message.
"""
import sys
from pathlib import Path

try:
    import yaml
except Exception:
    sys.stderr.write("PyYAML is required. Install with: pip install pyyaml\n")
    sys.exit(2)


def merge_frontmatter(path: Path, project: str, tag: str, extra_tag: str = None):
    text = path.read_text(encoding='utf-8')
    if not text.startswith('---\n'):
        # No frontmatter, prepend one
        fm = {}
        body = text
    else:
        # split frontmatter
        try:
            _, rest = text.split('---\n', 1)
        except ValueError:
            rest = text
        # rest starts with frontmatter content
        try:
            fm_text, body = rest.split('\n---\n', 1)
        except ValueError:
            # malformed, just return
            fm_text = rest
            body = ''
        try:
            fm = yaml.safe_load(fm_text) or {}
        except Exception:
            fm = {}

    # Merge fields
    if project:
        fm.setdefault('project', project)

    # Ensure tags is a list and normalize to lowercase strings
    tags = fm.get('tags')
    if tags is None:
        fm['tags'] = []
        tags = fm['tags']
    else:
        if not isinstance(tags, list):
            fm['tags'] = [str(tags).lower()]
            tags = fm['tags']
        else:
            fm['tags'] = [str(t).lower() for t in tags]
            tags = fm['tags']

    # Normalize incoming tags to lowercase
    tag_l = tag.lower() if tag else None
    extra_tag_l = extra_tag.lower() if extra_tag else None

    # Add main tag if provided
    if tag_l and tag_l not in tags:
        fm['tags'].append(tag_l)
    # Add extra tag (e.g., category) if provided
    if extra_tag_l and extra_tag_l not in tags:
        fm['tags'].append(extra_tag_l)
        # Also set the category field for clarity (lowercase)
        if 'category' not in fm:
            fm['category'] = extra_tag_l

    # Reconstruct file: ensure frontmatter is present
    out = ['---', yaml.safe_dump(fm, sort_keys=False).rstrip(), '---', '']
    out.append(body)
    path.write_text('\n'.join(out), encoding='utf-8')


def main(argv):
    if len(argv) < 4:
        print('Usage: _merge_frontmatter.py <file> <project> <project_tag> [extra_tag]')
        return 2
    path = Path(argv[1])
    project = argv[2]
    tag = argv[3]
    extra_tag = argv[4] if len(argv) > 4 else None
    merge_frontmatter(path, project, tag, extra_tag)
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv))

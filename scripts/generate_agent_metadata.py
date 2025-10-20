#!/usr/bin/env python3
"""
Scan .github for prompts, toolsets, and chatmodes and build a metadata JSON file.

Outputs: build/agent_metadata.json

This script extracts for each file:
- path
- type (prompt/toolset/chatmode)
- title (first Markdown H1/H2 or filename)
- description (first paragraph)
"""
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
GITHUB_DIR = ROOT / '.github'
OUT_DIR = ROOT / 'build'
OUT_FILE = OUT_DIR / 'agent_metadata.json'

SECTIONS = {
    'prompts': GITHUB_DIR / 'prompts',
    'toolsets': GITHUB_DIR / 'toolsets',
    'chatmodes': GITHUB_DIR / 'chatmodes',
}


def extract_title_and_description(text: str):
    # Title: first line that looks like a Markdown header (# or ##)
    title = None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('#'):
            title = re.sub(r'^#+\s*', '', line).strip()
            break
    if not title:
        # fallback to first non-empty line
        for line in text.splitlines():
            if line.strip():
                title = line.strip()
                break

    # Description: first paragraph (non-header) of text after title
    desc = None
    paragraphs = re.split(r"\n\s*\n", text.strip())
    for p in paragraphs:
        p = p.strip()
        if not p:
            continue
        if p.startswith('#'):
            continue
        desc = p.replace('\n', ' ').strip()
        break

    return title or '', desc or ''


def scan_section(name: str, path: Path):
    items = []
    if not path.exists():
        return items
    for p in sorted(path.glob('**/*')):
        if p.is_dir():
            continue
        try:
            text = p.read_text(encoding='utf-8')
        except Exception:
            # skip binary or unreadable
            continue
        title, desc = extract_title_and_description(text)
        items.append({
            'path': str(p.relative_to(ROOT)),
            'type': name,
            'filename': p.name,
            'title': title,
            'description': desc,
        })
    return items


def main():
    all_items = []
    for name, path in SECTIONS.items():
        items = scan_section(name, path)
        all_items.extend(items)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(json.dumps({'generated_at': __import__('datetime').datetime.utcnow().isoformat() + 'Z', 'items': all_items}, indent=2, ensure_ascii=False), encoding='utf-8')
    print(f'Wrote {OUT_FILE} with {len(all_items)} entries')


if __name__ == '__main__':
    main()

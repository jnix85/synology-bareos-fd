# Agent metadata generator

This repository includes a small utility that scans `.github` for agent-related content and generates a JSON metadata file at `build/agent_metadata.json`.

What it scans
- `.github/prompts` — prompt templates
- `.github/toolsets` — toolset documentation
- `.github/chatmodes` — chat mode descriptions

What it extracts
- path — relative path to the source file
- type — one of `prompts`, `toolsets`, `chatmodes`
- filename — the file's basename
- title — first Markdown header or first non-empty line
- description — first paragraph (non-header)

Run locally

```bash
# from repository root
python3 scripts/generate_agent_metadata.py
```

Or use the wrapper:

```bash
scripts/generate_agent_metadata.sh
```

CI

A GitHub Actions workflow `.github/workflows/generate_agent_metadata.yml` runs the generator on changes to `.github/**` and uploads the JSON as an artifact.

Notes
- The script skips binary/unreadable files.
- It's intentionally simple; if you want richer parsing (front-matter, tags), we can extend it to parse YAML front-matter or additional fields.

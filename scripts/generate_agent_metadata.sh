#!/usr/bin/env bash
# Wrapper to run the Python metadata generator
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${HERE}/.."
PYTHON="$(command -v python3 || command -v python)"

"$PYTHON" "$ROOT/scripts/generate_agent_metadata.py"
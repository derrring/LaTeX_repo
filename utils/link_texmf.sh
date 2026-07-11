#!/usr/bin/env bash
set -euo pipefail

# Keep one installer implementation and one safety policy.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/link_texmf.py" "$@"

#!/usr/bin/env bash
# Serve Puzzle Parlour at http://localhost:8080 (and on your Wi-Fi, for your phone).
#   ./run.sh                 start on port 8080 and open a browser tab
#   ./run.sh --port 9000     use another port
#   ./run.sh --no-browser    don't open a tab
#   ./run.sh --host 127.0.0.1   only this computer can connect
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then
  echo "No .venv yet. Run ./install.sh first (or just open index.html in a browser)." >&2
  exit 1
fi
exec .venv/bin/python serve.py "$@"

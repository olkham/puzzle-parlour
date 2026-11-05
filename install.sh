#!/usr/bin/env bash
# Set up Puzzle Parlour's local web server (a small Python virtual environment).
# Safe to run again: it reuses what is already there.
#
#   ./install.sh                 create or refresh .venv
#   ./install.sh --clean         delete .venv and install from scratch
#   ./install.sh --python PATH   use this interpreter without asking
#   ./install.sh --yes           don't ask; prefer python3
set -euo pipefail
cd "$(dirname "$0")"

VENV=".venv"
CLEAN=0
YES=0
PY=""

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --clean) CLEAN=1 ;;
    --python) [ $# -ge 2 ] || { echo "--python needs a path" >&2; exit 2; }; PY="$2"; shift ;;
    -y|--yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

if [ "$CLEAN" -eq 1 ] && [ -d "$VENV" ]; then
  echo "Removing $VENV for a fresh install..."
  rm -rf "$VENV"
fi

# A usable Python is 3.8 or newer.
py_version() { "$1" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null; }
py_ok() { "$1" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; }

if [ -x "$VENV/bin/python" ] && "$VENV/bin/python" -c 'import sys' >/dev/null 2>&1; then
  echo "Using existing $VENV ($("$VENV/bin/python" --version 2>&1))."
else
  if [ -d "$VENV" ]; then
    echo "$VENV looks broken; recreating it."
    rm -rf "$VENV"
  fi
  if [ -z "$PY" ]; then
    # check for both python and python3, and let you pick which one builds the .venv
    names=(); paths=()
    for cmd in python python3; do
      if command -v "$cmd" >/dev/null 2>&1 && py_ok "$cmd"; then
        names+=("$cmd"); paths+=("$(command -v "$cmd")")
      fi
    done
    if [ ${#names[@]} -eq 0 ]; then
      echo "Python 3.8+ was not found as 'python' or 'python3'." >&2
      echo "Install it from https://www.python.org/downloads/ (or your package manager) and run this again." >&2
      exit 1
    elif [ ${#names[@]} -eq 1 ]; then
      PY="${names[0]}"
      echo "Found ${names[0]} ($(py_version "${names[0]}")) at ${paths[0]}."
    else
      echo "Found two Pythons:"
      echo "  1) python   $(py_version python)   ${paths[0]}"
      echo "  2) python3  $(py_version python3)   ${paths[1]}"
      choice=2
      if [ "$YES" -eq 0 ] && [ -t 0 ]; then
        read -r -p "Which one should create the .venv? [1/2, Enter = 2]: " choice || true
        choice="${choice:-2}"
      fi
      case "$choice" in 1) PY=python ;; *) PY=python3 ;; esac
    fi
  elif ! py_ok "$PY"; then
    echo "'$PY' isn't Python 3.8 or newer." >&2
    exit 1
  fi
  echo "Creating $VENV with $PY..."
  if ! "$PY" -m venv "$VENV"; then
    echo "Couldn't create the virtual environment." >&2
    echo "On Debian/Ubuntu you may need: sudo apt install python3-venv" >&2
    exit 1
  fi
fi

echo "Installing the optional QR-code helper..."
if "$VENV/bin/python" -m pip install --disable-pip-version-check -q -r requirements.txt; then
  echo "Done."
else
  echo "Couldn't install qrcode (offline?). The games still work; you just won't get a QR code." >&2
fi

echo
echo "All set. Start the games with:  ./run.sh"
echo "(or just open index.html in a browser)"

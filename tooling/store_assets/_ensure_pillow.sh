# shellcheck shell=bash
# Source from store asset scripts: source "$(dirname "$0")/_ensure_pillow.sh"
#
# Picks a Python with Pillow: system python3 if available, else a local .venv
# (PEP 668 macOS/Homebrew blocks global pip install).

_STORE_ASSETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_STORE_ASSETS_VENV="$_STORE_ASSETS_DIR/.venv"
STORE_ASSETS_PYTHON=python3

ensure_pillow() {
  if python3 -c "import PIL" 2>/dev/null; then
    STORE_ASSETS_PYTHON=python3
    return 0
  fi

  if [[ -x "$_STORE_ASSETS_VENV/bin/python" ]] &&
    "$_STORE_ASSETS_VENV/bin/python" -c "import PIL" 2>/dev/null; then
    STORE_ASSETS_PYTHON="$_STORE_ASSETS_VENV/bin/python"
    return 0
  fi

  echo "Creating tooling/store_assets/.venv (Pillow for compose step)…" >&2
  python3 -m venv "$_STORE_ASSETS_VENV"
  "$_STORE_ASSETS_VENV/bin/pip" install -q -r "$_STORE_ASSETS_DIR/requirements.txt"
  STORE_ASSETS_PYTHON="$_STORE_ASSETS_VENV/bin/python"
}

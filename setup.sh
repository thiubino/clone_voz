#!/usr/bin/env bash
# Clone and install VibeVoice (community fork) into a local virtualenv.
set -euo pipefail

REPO_URL="https://github.com/vibevoice-community/VibeVoice"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$ROOT/VibeVoice"
VENV="$ROOT/.venv"

if [ -d "$TARGET_DIR/.git" ]; then
  echo "==> VibeVoice already cloned, pulling latest"
  git -C "$TARGET_DIR" pull --ff-only
else
  echo "==> Cloning VibeVoice"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

# A virtualenv is not optional here: VibeVoice depends on aiortc, which needs a
# newer cryptography than the distro package. Installing into the system
# interpreter fails with "Cannot uninstall cryptography ... installed by debian".
if [ ! -d "$VENV" ]; then
  echo "==> Creating virtualenv at $VENV"
  python3 -m venv "$VENV"
fi
"$VENV/bin/pip" install --upgrade pip setuptools wheel

echo "==> Installing VibeVoice in editable mode"
"$VENV/bin/pip" install -e "$TARGET_DIR"

echo "==> Done. Activate with: source .venv/bin/activate"
"$VENV/bin/python" -c "import vibevoice; print('vibevoice ok:', vibevoice.__file__)"

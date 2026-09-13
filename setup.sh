#!/usr/bin/env bash
# Clone and install VibeVoice (community fork) in editable mode.
set -euo pipefail

REPO_URL="https://github.com/vibevoice-community/VibeVoice"
TARGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/VibeVoice"

if [ -d "$TARGET_DIR/.git" ]; then
  echo "==> VibeVoice already cloned, pulling latest"
  git -C "$TARGET_DIR" pull --ff-only
else
  echo "==> Cloning VibeVoice"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

echo "==> Installing VibeVoice in editable mode"
cd "$TARGET_DIR"
pip install -e .

echo "==> Done. Verify with: python -c 'import vibevoice; print(vibevoice.__file__)'"

#!/usr/bin/env bash

set -e

if command -v godot >/dev/null 2>&1; then
  GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot executable not found."
  exit 1
fi

echo "Validating CoreCritters..."

"$GODOT" \
  --headless \
  --editor \
  --path . \
  --quit

echo "Validation passed."
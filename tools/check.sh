#!/usr/bin/env bash
set -euo pipefail

if command -v godot >/dev/null 2>&1; then
  GODOT="$(command -v godot)"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT="$(command -v godot4)"
elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot executable not found." >&2
  exit 1
fi

echo "Validating CoreCritters with $GODOT..."
"$GODOT" --headless --path . --log-file /private/tmp/corecritters-check.log --fixed-fps 60 --quit-after 1200
if rg -n 'SCRIPT ERROR|ERROR: Failed to load|ERROR: Parse Error|ERROR: Compile Error' /private/tmp/corecritters-check.log; then
  echo "Godot reported script errors." >&2
  exit 1
fi
echo "Validation passed."

---
name: validate-godot
description: Validate CoreCritters after code or resource changes. Use before completing implementation tasks.
---

Run:

./tools/check.sh

If it fails:
1. Inspect the first relevant error.
2. Fix it.
3. Run validation again.
4. Do not report completion until it passes.
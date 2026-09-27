---
name: add-unit
description: Add a new CoreCritters creature using the existing UnitData + behavior architecture. Use when creating a new playable unit.
---

Before starting:
- Read AGENTS.md.
- Inspect game/units/.
- Reuse the existing generic Unit scene.

For each new unit:
1. Create UnitData resource.
2. Create a focused behavior script only if unique behavior is needed.
3. Add required art references.
4. Do not modify unit.gd unless the generic runtime truly needs a new capability.
5. Do not hardcode the unit ID into unrelated systems.
6. Run ./tools/check.sh.

Report:
- files created
- behavior added
- any shared-system change and why it was unavoidable
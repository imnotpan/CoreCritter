---
name: add-card
description: Add or configure collectible cards for CoreCritters without changing collection architecture. Use for new cards, rarity, duplicates and upgrade data.
---

Read:
- AGENTS.md
- game/cards/
- docs/game_design.md

Rules:
- Cards reference UnitData.
- Do not duplicate unit runtime logic inside CardData.
- Rarity is data.
- Upgrade requirements are data.
- Do not add special cases to CardCollection for individual cards.

Run ./tools/check.sh.
# Architecture

Main is the composition root.

Main
├── DesktopOverlay
├── GameSession
│   ├── Army
│   │   └── Units
│   ├── Threats
│   ├── CoreTarget
│   ├── Economy
│   └── Progression
└── UI

## Dependency flow

Call downward.
Signal upward.
Pass data/resources across.

## Content model

Static game content uses Godot Resources:
- UnitData
- CardData
- CoreData
- PackData
- WorldData

Runtime nodes consume those Resources.

## UI

UI displays state and emits commands.

UI does not calculate:
- combat
- rewards
- progression
- card drops
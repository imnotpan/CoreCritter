# Architecture

Main is the composition root.

Application presentation follows AppFlow: MAIN_MENU → PRE_RUN → ACTIVE_RUN →
RUN_RESULTS → PRE_RUN. Collection and upgrades are available from the menu.

Permanent CardCollection progression and the editable next-run DeckLoadout
are saved through SaveData. Starting a run creates a sealed RunLoadout containing
three distinct unlocked CardData references and captured star levels.
Army and the active card HUD consume only RunLoadout. CardCommands tracks optional
command cooldowns and delegates effects to the existing UnitBehavior Resources.
Units own runtime HP/status durations; Army owns KO recovery slots and spawning.
CoreBehavior requests telegraphed CoreInteraction nodes through GameSession.
RunSession owns a bounded pending boon choice; BoonData applies run-only Army
modifiers. Ending a run clears commands, interactions and modifiers, leaving
permanent collection and saved data untouched.

GameSession owns combat nodes and an active RunSession. RunSession owns the
selected world, core index and reward summary. WorldProgression owns persistent
world unlocks and completions. The final core ends the run; exiting early retains
earned rewards. Combat and passive pack timers run only during an active run.

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

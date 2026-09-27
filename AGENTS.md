# CoreCritters

CoreCritters is a passive desktop creature-collector auto-battler built with Godot 4.

The game runs as a small transparent overlay on the desktop while the user works.

## Product rules

The player must never be punished for focusing on work.

Passive gameplay:
- units spawn automatically
- units move automatically
- units attack automatically
- progress continues while the player ignores the game

Player interaction is mainly:
- configuring the army
- opening card packs
- upgrading cards
- clicking optional threats
- viewing collection and progression

There is no traditional game over during passive play.

## Architecture

Use feature-based folders under `game/`.

Rules:
- Typed GDScript whenever practical.
- Prefer small focused scripts.
- Keep gameplay scripts roughly under 250 lines when practical.
- Static game data belongs in Godot Resources.
- Runtime behavior belongs in scenes/scripts.
- UI must not contain gameplay logic.
- Call downward, signal upward.
- No long absolute SceneTree paths.
- No unnecessary Autoloads.
- Avoid global state.
- New units should not require modifying unrelated systems.
- New cards should not require modifying unrelated systems.
- New threats should not require modifying unrelated systems.

## Scene dependency rule

Call downward.
Signal upward.
Pass data/resources across.

Avoid:
- `get_node("../../../../")`
- searching the entire SceneTree for dependencies
- hardcoded references to unrelated scenes

Prefer:
- exported references
- dependency injection
- signals
- Resources

## Core data model

UnitData:
static configuration of a unit.

Unit:
runtime unit instance.

CardData:
collectible representation of a unit.

ArmyLoadout:
selected cards used to spawn units.

CoreData:
configuration of an enemy core.

SaveData:
persistent player state.

## Scope

Do not refactor unrelated systems unless explicitly requested.

Prefer minimal, focused changes.

## Validation

Before reporting a task complete, run:

./tools/check.sh

Do not report completion if validation fails.

## Git workflow

- Do not commit during implementation unless explicitly requested.
- When a focused task is complete and the user requests closure, use `.agents/skills/finish-task/SKILL.md`.
- Validate before committing and inspect the diff before staging.
- Never commit unrelated user changes.
- Prefer one focused commit per milestone or feature.
- Never push unless explicitly requested.

## Context efficiency

- Inspect only files relevant to the current task; do not reread unrelated subsystems without reason.
- Refer to `docs/architecture.md` and `docs/game_design.md` when relevant instead of repeating them in task reports.
- Create documentation only when it provides durable value.
- Keep completion reports concise; use repository state and Git history instead of repeating past milestone descriptions.
- Do not refactor unrelated working systems.

# CoreCritters — Game Design

## Fantasy

Build an army of strange collectible creatures that automatically attacks increasingly ridiculous enemy cores while the player works.

## Core loop

Prepare world and three-card deck
→ start run with frozen cards and stars
→ Work
→ passive combat
→ earn coins
→ damage/destroy core
→ earn card packs
→ open packs
→ collect creatures
→ defeat the world's final boss
→ view results
→ upgrade collection and prepare the next deck

New creatures unlocked from packs during combat are AVAILABLE NEXT RUN.
They never change the current army. Upgrades and deck editing happen outside
combat. Exiting a run keeps rewards already earned.

## Passive experience

The game must work well when ignored.

A weak army progresses slowly.
A strong army progresses quickly.

The player must never lose permanent progress for ignoring the game. Units may
be damaged, debuffed, disabled or KO'd; Army automatically replaces them after a
short recovery delay. An army wipe never ends the run or resets Core HP. Cards,
upgrades and permanent progression are never lost. Weak builds and inattention
mean slower progression; strong builds and optional interaction mean faster progress.

The game plays itself, but regularly offers optional opportunities to intervene.
Ignoring it for minutes or an entire run segment must remain safe. Aim for mostly
automatic play, occasional micro interactions and some strategic choices, without
literal percentage quotas or mandatory interaction every few seconds.

## Interaction

Primary:
- army building
- card collection
- pack opening
- upgrades

Secondary:
- telegraphed Core attacks and temporary clickable hazards (expire automatically)
- optional clickable threats
- optional active card commands with long cooldowns and a quiet READY state
- temporary run boons: one pending choice of three after non-final Cores; gameplay
  continues until the player chooses, and all effects disappear when the run ends
- cosmetics
- collection browsing

The current three-card RunLoadout and captured stars remain immutable. Commands
accelerate combat without swapping cards. Boons modify only runtime run effects,
never UnitData assets, CardCollection, permanent stars or the next-run deck.
Every harmful Core attack gives a readable warning before resolving; reacting,
cleaning hazards and freeing trapped units are always optional.

## Avoid

- mandatory micro-management
- traditional game over
- constant notifications
- paid loot boxes
- excessive stats
- mechanics that steal keyboard focus unnecessarily

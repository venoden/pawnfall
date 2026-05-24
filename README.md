# Pawnfall

**Pawnfall** is a small 2D dungeon crawler prototype built in Godot.

You play as the Pawn, a tiny hooded dungeon crawler fighting goblins, surviving waves, and slowly pushing deeper into the dungeon.

This project is currently in early alpha and is being developed in small playable releases.

## Current Version

**v0.0.0-alpha.2**

## Current Gameplay

- Move around a top-down dungeon room
- Fight goblin enemies
- Defeat the Gobboss
- Use the current weapon system
- Pick up health items
- Reach victory after defeating the boss
- Pause gameplay with a pause/menu overlay
- Experience defeat and victory screens with gameplay properly frozen

## Alpha.2 Update

Alpha.2 focuses on improving the core room and gameplay feel.

### Added / Improved

- Expanded the main dungeon room for more playable space
- Adjusted the camera zoom to better fit the larger room
- Fixed mouse cursor visibility during pause/menu overlays
- Improved button interaction while paused or in menu states
- Improved pause, defeat, and victory overlay behavior
- Ensured gameplay properly freezes during pause, defeat, and victory states
- Improved Gobboss movement behavior after the larger room update
- Preserved sprite scale relationships between the Pawn, goblins, and Gobboss

### Temporary Changes

- Removed current obstacle placement from alpha.2
- Obstacle layout and new obstacle sprites are deferred to alpha.3
- This avoids shipping known spacing/cropping issues from the current obstacle sprite sheet

### Known Visual Issue

- The Pawn still does not clearly appear to hold the mace during gameplay
- The mace works mechanically, but the visual attachment/anchor needs improvement
- This has been moved into a dedicated follow-up issue for a focused fix

## Repository Notes

- Added a root `.gitignore` for Godot project cleanup
- Local Godot cache files, build/export folders, editor files, OS junk, and environment files should be kept out of version control
- The current stable alpha.2 work should remain on `main`
- Focused fixes can be handled on separate branches before merging back into `main`

## Planned Alpha.3 Focus

Alpha.3 is expected to focus on presentation, sprites, and structure improvements.

Planned direction:

- Main menu implementation
- Updated sprite assets
- Cleaner obstacle sprites and placement
- Better title/menu flow
- Dedicated fix for the Pawn/mace visual anchor issue
- Possible early room progression planning

## Future Progression Idea

A possible future update may cover the staircase with a wooden trapdoor.

Planned concept:

- The trapdoor stays closed during combat
- The player must defeat at least 8 goblins and the Gobboss
- After those conditions are met, the trapdoor opens
- The player can walk down through the opened trapdoor
- Entering the trapdoor can transition or teleport the player to a new room

This is a future progression idea and is not part of alpha.2.

## Version Roadmap

Planned release path:

- v0.0.0-alpha.1
- v0.0.0-alpha.2
- v0.0.0-alpha.3
- v0.0.0-alpha.4
- v0.0.0-alpha.5
- v0.0.0-beta.1
- v0.0.0-beta.2
- v0.0.0-beta.3
- v1.0.0

## Development Notes

This is an early prototype. Systems, sprites, room layouts, menus, balance, and progression are all expected to change as the project develops.

The current goal is to build the game in small stable chunks instead of adding too many unfinished systems at once.

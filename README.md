# Pawnfall

**Pawnfall** is a small 2D dungeon crawler prototype built in Godot.

You play as the Pawn, a tiny hooded dungeon crawler fighting goblins, surviving waves, unlocking dungeon rewards, and slowly pushing deeper into the dungeon.

This project is currently in early internal alpha and is being developed in small playable milestones.

## Current Version

**v0.0.0-alpha.3**

## Current Gameplay

- Start from a dedicated main menu
- Move around a top-down dungeon room
- Fight goblin enemies
- Defeat the Gobboss
- Use the current weapon system
- Pick up health items
- Pause gameplay with a pause/menu overlay
- Experience defeat and victory screens
- Defeat goblins to progress toward dungeon rewards
- Collect a key after enough goblins are defeated
- Use the key to unlock a chest
- Reveal and collect the Bluntbow from the opened chest

## v0.0.0-alpha.3 Focus

This alpha update focuses on adding the first real menu structure and improving dungeon progression.

### Added

- Main menu scene
- Main menu UI assets
- Play/menu entry flow
- Chest-based reward progression
- Key pickup flow for unlocking the chest
- Bluntbow pickup reveal after opening the chest

### Improved / Cleaned Up

- Updated the project toward a clearer internal alpha milestone structure
- Preserved the chest/key unlock work while merging the main menu branch
- Removed generated Godot `.godot` editor/cache files from version control
- Continued testing around combat, pickups, pause behavior, victory, and defeat states

## Alpha Status

Pawnfall is currently in internal alpha.

Alpha builds are used for development, testing, balance changes, visual updates, and core gameplay experiments.

There is no public downloadable release yet.

## Planned Development Roadmap

Pawnfall is planned to move through:

- 5 internal alpha builds
- 3 beta builds
- full release

The first public downloadable build is planned for the beta stage.

## Current Testing Priorities

- Confirm the main menu works correctly
- Confirm Play starts the dungeon properly
- Confirm pause freezes gameplay correctly
- Confirm defeat and victory screens behave correctly
- Confirm goblins and Gobboss still deal damage properly
- Confirm health pickups function correctly
- Confirm the key drops after the intended goblin progression
- Confirm the chest unlocks only after the key is collected
- Confirm the Bluntbow appears after the chest opens
- Confirm no required sprites, scenes, or scripts are missing

## Development Notes

Pawnfall is being developed with small focused updates.

The current goal is to keep each alpha milestone playable, testable, and easy to understand before adding larger systems.

Generated Godot editor/cache files should not be tracked in version control.

## Built With

- Godot Engine
- GitHub / GitHub Desktop

# Player Character Sprite Direction

Canonical player design as of this pass:

- Hooded, orange/red robe silhouette.
- Dark face void.
- Two small yellow eyes.
- Chunky pixel-art proportions.
- Compact, readable top-down/action-RPG scale.
- Current exact player sprite lives at `res://sprites/main_pawn.png`.
- Source file copied from `C:/Users/dusti/OneDrive/Desktop/Dungeon Crawler/Sprites/Allies/main_pawn.png`.
- Source dimensions: `1024 x 1024`, `Format32bppArgb`.
- Source SHA-256 at copy time: `A236BCE7D345DC5878C21B60363E87EAF84B5C363416A06082B6DB71D9A051BD`.
- Do not redesign, crop, trace, recolor, or resize the source PNG.

Current in-game assumptions:

- The player scene expects the character texture on `player/Player.tscn` node `Visual/Body`.
- `Visual/Body` currently displays the 1024px source at `0.0625` scene scale to match the prototype footprint while preserving the original PNG file.
- The collision radius is currently `18`.
- The sprite should stay visually centered around its canvas center.
- Transparent background is preferred.
- If the source image has a baked gray/background glow, keep it unless the user supplies a replacement transparent version.

When replacing with another PNG:

- Keep the source resolution and pixel count documented here.
- Use nearest-neighbor import settings in Godot.
- Tune `Visual/Body` scale and offset in `player/Player.tscn`.
- Retune `CollisionShape2D` only if the playable footprint changes.

# Halo N Fin - Godot Level 1

This project recreates a simple **Level 1** in Godot using:

- `assets/walk_strip.png` for the dog walk animation strip (8 frames).
- `assets/level1_background.png` for the level image.

## Setup

1. Copy your provided walk animation strip image to:
   - `assets/walk_strip.png`
2. Copy your provided level image to:
   - `assets/level1_background.png`
3. Open the folder in Godot 4.2+.
4. Run the project.

## Controls

- `A / D`: Move left/right
- `Space`: Jump

## Scene layout

- `scenes/Level1.tscn`: Level 1 scene with background, ground collision, player, and camera.
- `scenes/Player.tscn`: Character scene using `AnimatedSprite2D` with `idle` + `walk` animations from the walk strip.
- `scripts/player.gd`: Basic platformer movement + animation state switching.


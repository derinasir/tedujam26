# 🖌️ Godot 4 – World-Space Brush & Paint System

Paint directly onto sprites **in the game world** — no UI canvas, no overlays.
Each sprite maintains its own paintable texture. The brush works entirely in world space.

## Files

| File | Purpose |
|------|---------|
| `paintable_sprite.gd` | Attach to any `Sprite2D` to make it paintable |
| `world_brush.gd` | Add once to your scene — handles all input & painting |
| `demo_world.tscn` | Ready-to-run demo with 3 paintable sprites |

## Quick Setup

**Step 1** — Add `WorldBrush` to your scene (one per scene):
```
Node2D (your scene root)
└── WorldBrush   ← attach world_brush.gd
```

**Step 2** — Attach `paintable_sprite.gd` to any `Sprite2D` you want to paint on:
```gdscript
# In the Inspector, set:
texture_width  = 256   # resolution of the paintable texture
texture_height = 256
base_color     = Color.WHITE  # starting fill color
```
If the Sprite2D already has a texture, the script bakes it into a paintable image automatically.

**Step 3** — Run and click to paint.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `1` | Round brush |
| `2` | Square brush |
| `3` | Spray brush |
| `E` | Toggle eraser |
| `C` | Clear all sprites |
| `+` / `-` | Grow / shrink brush |

## WorldBrush API

Change brush settings at runtime from any script:

```gdscript
@onready var brush := $WorldBrush

brush.brush_color = Color.BLUE
brush.brush_size  = 20         # radius in texture pixels
brush.brush_type  = "spray"   # "round" | "square" | "spray"
brush.opacity     = 0.5
brush.is_erasing  = true

# If you spawn a PaintableSprite at runtime, register it:
brush.register_sprite($NewSprite)
```

## PaintableSprite API

```gdscript
@onready var wall := $Wall

wall.clear()                  # reset to base_color
wall.save("user://wall.png")  # export texture

# Paint manually from code (e.g. bullet hit):
var pixel := wall.world_to_pixel(hit_position)
wall.paint(pixel, radius=8, color=Color.BLACK, brush_type="round", opacity=1.0)
wall.erase(pixel, radius=8)
```

## Use Case Examples

- **Bullet holes / damage decals** — call `paint()` on hit from a raycast
- **Terrain painting** — paint grass/dirt/snow onto a ground sprite
- **Graffiti / tagging** — player-driven world decoration
- **Hidden messages** — start with a dark sprite, erase to reveal content underneath

## Tips

- Use **higher texture resolution** (512×512) for large sprites that need fine detail.
- Use **lower resolution** (64×64) for pixelated/retro looks.
- The brush size is in **texture pixels**, not world units — scale accordingly.
- For Camera2D scenes, `WorldBrush` automatically accounts for the camera offset.

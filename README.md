# 🎨 Godot 4 – Brush & Draw System

A fully-featured painting/drawing canvas for Godot 4.

## Files

| File | Purpose |
|------|---------|
| `drawing_canvas.gd` | Core drawing engine (attach to a `TextureRect`) |
| `main.gd` | UI controller (attach to root `Control`) |
| `main.tscn` | Complete scene (open this in Godot) |

## Quick Setup

1. Copy all three files into your Godot 4 project folder (`res://`).
2. Open **main.tscn** as your main scene.
3. Run the project — the drawing canvas works immediately.

## Features

### Brush Types
| Type | Description |
|------|-------------|
| **Round** | Soft circular brush, great for freehand |
| **Square** | Pixel-art style hard square brush |
| **Spray** | Scattered particles for airbrush effect |

### Controls
- **Left click + drag** → Draw on canvas
- **Color picker** → Choose any brush color
- **Size slider** → 1 – 80 px brush radius
- **Opacity slider** → 5% – 100% transparency blending
- **Eraser toggle** → Paint with white (erases to background)
- **Clear** → Reset canvas to white
- **Save PNG** → Exports to `user://my_drawing.png`

## Customization

### Change canvas resolution
In `drawing_canvas.gd`, edit:
```gdscript
var canvas_size := Vector2i(1280, 720)
```

### Add a custom brush shape
Implement a new `_draw_*_brush()` method and add it to the `match` block in `_draw_brush()`:
```gdscript
"star":
	_draw_star_brush(pos, half, color)
```

### Use the canvas in your own scene
Attach `drawing_canvas.gd` to any `TextureRect` node and call its API:
```gdscript
canvas.set_brush_color(Color.RED)
canvas.set_brush_size(20)
canvas.set_brush_type("spray")  # "round" | "square" | "spray"
canvas.set_opacity(0.5)
canvas.set_erasing(true)
canvas.clear_canvas()
canvas.save_canvas("user://output.png")
```

## Notes
- Built for **Godot 4.x** (uses `Image.create`, `ImageTexture.create_from_image`).
- The canvas uses alpha-blending for opacity support.
- Line smoothing is done by interpolating brush stamps between mouse positions.

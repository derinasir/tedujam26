## WorldDrawLayer.gd
## Add this as a CanvasLayer child in your scene.
## It draws on top of the world using a viewport texture that moves with the camera,
## so strokes stay locked to world coordinates — not screen coordinates.
##
## Scene setup:
##   YourScene
##   ├── ... your world nodes ...
##   └── WorldDrawLayer   ← attach this script (as a Node2D, NOT CanvasLayer)

extends Node2D

# --- Brush settings ---
@export var brush_color: Color = Color(1, 0.2, 0.2, 1)
@export var brush_size: int = 8
@export var brush_type: String = "round"   # "round" | "square" | "spray"
@export var opacity: float = 1.0

# --- Internal ---
# All strokes are stored as world-space data so they survive camera movement.
# Each stroke = { color, size, type, opacity, points: [Vector2, ...] }
var _strokes: Array = []
var _current_stroke: Dictionary = {}
var _is_drawing := false
var _last_world_pos := Vector2.ZERO

# Cursor
var _cursor_pos := Vector2.ZERO
var _show_cursor := false

func _ready() -> void:
	# Draw on top of everything in the world
	z_index = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_drawing = true
			_last_world_pos = _screen_to_world(event.position)
			_current_stroke = {
				"color": brush_color,
				"size": brush_size,
				"type": brush_type,
				"opacity": opacity,
				"points": [_last_world_pos]
			}
		else:
			if _is_drawing and not _current_stroke.is_empty():
				_strokes.append(_current_stroke)
				_current_stroke = {}
			_is_drawing = false

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_undo_last_stroke()

	elif event is InputEventMouseMotion:
		var world_pos := _screen_to_world(event.position)
		_cursor_pos = world_pos
		_show_cursor = true

		if _is_drawing:
			# Only add a new point if we've moved far enough (reduces point count)
			if world_pos.distance_to(_last_world_pos) >= max(1.0, brush_size * 0.3):
				_current_stroke["points"].append(world_pos)
				_last_world_pos = world_pos

		queue_redraw()

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Z:
				if event.ctrl_pressed:
					_undo_last_stroke()
			KEY_C:
				if event.ctrl_pressed:
					_clear_all()
			KEY_1: brush_type = "round"
			KEY_2: brush_type = "square"
			KEY_3: brush_type = "spray"
			KEY_EQUAL, KEY_KP_ADD:
				brush_size = min(brush_size + 2, 120)
			KEY_MINUS, KEY_KP_SUBTRACT:
				brush_size = max(brush_size - 2, 1)

func _draw() -> void:
	# Draw all completed strokes
	for stroke in _strokes:
		_draw_stroke(stroke)

	# Draw the in-progress stroke
	if _is_drawing and not _current_stroke.is_empty():
		_draw_stroke(_current_stroke)

	# Draw cursor
	if _show_cursor:
		var cursor_color := Color(0.2, 0.7, 1.0, 0.85)
		draw_arc(_cursor_pos, float(brush_size), 0.0, TAU, 32, cursor_color, 1.5)

func _draw_stroke(stroke: Dictionary) -> void:
	var points: Array = stroke["points"]
	if points.is_empty():
		return

	var color: Color = stroke["color"]
	var size: int = stroke["size"]
	var type: String = stroke["type"]
	var alpha: float = stroke["opacity"]
	var draw_color := Color(color.r, color.g, color.b, alpha)

	if points.size() == 1:
		_draw_stamp(points[0], size, type, draw_color)
		return

	# Interpolate stamps along the stroke path
	for i in range(1, points.size()):
		var from: Vector2 = points[i - 1]
		var to: Vector2 = points[i]
		var dist := from.distance_to(to)
		var steps = max(int(dist / max(1, size * 0.4)), 1)
		for s in steps:
			var t := float(s) / float(steps)
			_draw_stamp(from.lerp(to, t), size, type, draw_color)

	# Always draw the final point
	_draw_stamp(points[-1], size, type, draw_color)

func _draw_stamp(pos: Vector2, size: int, type: String, color: Color) -> void:
	match type:
		"round":
			draw_circle(pos, float(size), color)
		"square":
			var rect := Rect2(pos - Vector2(size, size), Vector2(size * 2, size * 2))
			draw_rect(rect, color)
		"spray":
			for _i in size * 3:
				var angle := randf() * TAU
				var dist := randf() * size
				var dot_pos := pos + Vector2(cos(angle), sin(angle)) * dist
				draw_circle(dot_pos, 1.0, color)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _undo_last_stroke() -> void:
	if not _strokes.is_empty():
		_strokes.pop_back()
		queue_redraw()

func _clear_all() -> void:
	_strokes.clear()
	_current_stroke = {}
	queue_redraw()

# --- Public API ---

func set_brush_color(color: Color) -> void:
	brush_color = color

func set_brush_size(size: int) -> void:
	brush_size = clamp(size, 1, 120)

func set_brush_type(type: String) -> void:
	brush_type = type  # "round" | "square" | "spray"

func set_opacity(value: float) -> void:
	opacity = clamp(value, 0.05, 1.0)

func undo() -> void:
	_undo_last_stroke()

func clear() -> void:
	_clear_all()

## WorldDrawLayer.gd
## Draws on top of the world without modifying any sprites.
## Strokes are locked to world coordinates — camera pan/zoom safe.
##
## Optimization: completed strokes are baked into a flat array of pre-computed
## stamp positions so _draw() never re-interpolates finished geometry.
## Only the active stroke does live interpolation.
##
## Scene setup:
##   YourScene
##   ├── ... your world nodes ...
##   └── WorldDrawLayer   ← Node2D with this script

extends Node2D

# --- Brush settings ---
@export var brush_color: Color = Color(1, 0.2, 0.2, 1)
@export var brush_size: int = 8
@export var brush_type: String = "round"   # "round" | "square" | "spray"
@export var opacity: float = 1.0

# --- Baked strokes ---
# Each entry is a pre-computed, ready-to-draw stroke:
# { color: Color, size: int, type: String, stamps: PackedVector2Array }
var _baked_strokes: Array = []

# --- Active (in-progress) stroke ---
# Stores raw input points; baked on mouse-release.
var _active_points: PackedVector2Array = []
var _active_color: Color
var _active_size: int
var _active_type: String
var _active_opacity: float
var _active_last_baked_idx: int = 0   # how many segments are already in _active_stamps
var _active_stamps: PackedVector2Array = []  # incrementally built during drawing

var _is_drawing := false
var _last_world_pos := Vector2.ZERO

# Cursor
var _cursor_pos := Vector2.ZERO

func _ready() -> void:
	z_index = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_drawing = true
			_last_world_pos = _screen_to_world(event.position)
			_active_points = PackedVector2Array([_last_world_pos])
			_active_color = brush_color
			_active_size = brush_size
			_active_type = brush_type
			_active_opacity = opacity
			_active_last_baked_idx = 0
			_active_stamps = PackedVector2Array()
			# Draw the first stamp
			_active_stamps.append_array(_stamps_for_segment(_last_world_pos, _last_world_pos, _active_size, _active_type))
			queue_redraw()
		else:
			if _is_drawing:
				# Bake the finished stroke — no more interpolation ever needed for it
				if not _active_stamps.is_empty():
					_baked_strokes.append({
						"color": Color(_active_color.r, _active_color.g, _active_color.b, _active_opacity),
						"size": _active_size,
						"type": _active_type,
						"stamps": _active_stamps.duplicate()
					})
				_active_points = PackedVector2Array()
				_active_stamps = PackedVector2Array()
				_is_drawing = false
				queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_undo_last_stroke()

	elif event is InputEventMouseMotion:
		var world_pos := _screen_to_world(event.position)
		_cursor_pos = world_pos

		if _is_drawing:
			var min_dist = max(1.0, _active_size * 0.35)
			if world_pos.distance_to(_last_world_pos) >= min_dist:
				# Incrementally append only the NEW segment's stamps
				var new_stamps := _stamps_for_segment(_last_world_pos, world_pos, _active_size, _active_type)
				_active_stamps.append_array(new_stamps)
				_active_points.append(world_pos)
				_last_world_pos = world_pos
				queue_redraw()  # only redraw when a new stamp was actually added

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

## Pre-compute stamp positions for one segment between two points.
## This is the only place interpolation happens, and only for new input.
func _stamps_for_segment(from: Vector2, to: Vector2, size: int, type: String) -> PackedVector2Array:
	var result := PackedVector2Array()
	var dist := from.distance_to(to)
	var steps = max(int(dist / max(1.0, size * 0.4)), 1)
	for s in steps:
		var t := float(s) / float(steps)
		var pos := from.lerp(to, t)
		if type == "spray":
			# Spray needs multiple random dots per stamp — store each dot individually
			for _i in size * 3:
				var angle := randf() * TAU
				var d := randf() * size
				result.append(pos + Vector2(cos(angle), sin(angle)) * d)
		else:
			result.append(pos)
	return result

func _draw() -> void:
	# Draw baked strokes — just iterate pre-computed positions, zero math
	for stroke in _baked_strokes:
		_draw_baked(stroke)

	# Draw active stroke — also pre-computed incrementally, no re-interpolation
	if _is_drawing and not _active_stamps.is_empty():
		var draw_color := Color(_active_color.r, _active_color.g, _active_color.b, _active_opacity)
		_draw_stamps(_active_stamps, _active_size, _active_type, draw_color)

	# Cursor ring
	draw_arc(_cursor_pos, float(brush_size), 0.0, TAU, 32, Color(0.2, 0.7, 1.0, 0.85), 1.5)

func _draw_baked(stroke: Dictionary) -> void:
	_draw_stamps(stroke["stamps"], stroke["size"], stroke["type"], stroke["color"])

func _draw_stamps(stamps: PackedVector2Array, size: int, type: String, color: Color) -> void:
	var radius := float(size)
	match type:
		"round":
			for pos in stamps:
				draw_circle(pos, radius, color)
		"square":
			var half := Vector2(size, size)
			var full := half * 2
			for pos in stamps:
				draw_rect(Rect2(pos - half, full), color)
		"spray":
			# For spray, each entry is already an individual dot
			for pos in stamps:
				draw_circle(pos, 1.0, color)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _undo_last_stroke() -> void:
	if _baked_strokes.is_empty():
		return
	_baked_strokes.pop_back()
	queue_redraw()

func _clear_all() -> void:
	_baked_strokes.clear()
	_active_points = PackedVector2Array()
	_active_stamps = PackedVector2Array()
	_is_drawing = false
	queue_redraw()

# --- Public API ---

func set_brush_color(color: Color) -> void:
	brush_color = color

func set_brush_size(size: int) -> void:
	brush_size = clamp(size, 1, 120)

func set_brush_type(type: String) -> void:
	brush_type = type

func set_opacity(value: float) -> void:
	opacity = clamp(value, 0.05, 1.0)

func undo() -> void:
	_undo_last_stroke()

func clear() -> void:
	_clear_all()

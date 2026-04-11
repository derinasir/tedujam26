## WorldDrawLayer.gd
## Draws on top of the world without modifying any sprites.
## Strokes stay locked to world coordinates — camera pan/zoom safe.
##
## Architecture:
##   Completed strokes are painted directly into an Image (pixel buffer).
##   The TextureRect displaying that image never changes cost regardless of
##   how many strokes have been drawn — it is just one texture upload per stroke.
##
##   The active (in-progress) stroke is the ONLY thing rendered via _draw(),
##   so _draw() cost stays tiny and constant no matter how much is on screen.
##
##   Undo is supported by keeping a snapshot of the Image before each stroke.
##
## Scene setup:
##   YourScene
##   ├── Camera2D
##   ├── ... world nodes ...
##   └── WorldDrawLayer   ← Node2D with this script

extends Node2D

# --- Brush settings ---
@export var brush_color: Color = Color(1, 0.2, 0.2, 1)
@export var brush_size: int = 8
@export var brush_type: String = "round"   # "round" | "square" | "spray"
@export var opacity: float = 1.0
@export var is_erasing: bool = false

# --- Canvas config ---
# World-unit area the paint canvas covers, centered on origin.
@export var canvas_world_size: Vector2 = Vector2(4096, 4096)
# Pixels per world unit. Higher = sharper but more memory.
@export var pixels_per_unit: float = 1.0

# --- Internal: persistent pixel buffer ---
var _image: Image
var _image_texture: ImageTexture
var _texture_rect: TextureRect
var _canvas_pixel_size: Vector2i
var _undo_stack: Array[Image] = []

# --- Internal: active stroke (live _draw preview only) ---
var _active_stamps: PackedVector2Array = []
var _active_color: Color
var _active_size: int
var _active_type: String
var _active_opacity: float
var _active_erasing: bool
var _is_drawing := false
var _last_world_pos := Vector2.ZERO

# Cursor
var _cursor_pos := Vector2.ZERO

func _ready() -> void:
	z_index = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_init_canvas()

func _init_canvas() -> void:
	_canvas_pixel_size = Vector2i(
		int(canvas_world_size.x * pixels_per_unit),
		int(canvas_world_size.y * pixels_per_unit)
	)
	_image = Image.create(_canvas_pixel_size.x, _canvas_pixel_size.y, false, Image.FORMAT_RGBA8)
	_image.fill(Color(0, 0, 0, 0))
	_image_texture = ImageTexture.create_from_image(_image)

	_texture_rect = TextureRect.new()
	_texture_rect.texture = _image_texture
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.size = canvas_world_size
	_texture_rect.position = -canvas_world_size * 0.5
	add_child(_texture_rect)

# --- Input ---

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_drawing = true
			_last_world_pos = _screen_to_world(event.position)
			_active_color = brush_color
			_active_size = brush_size
			_active_type = brush_type
			_active_opacity = opacity
			_active_erasing = is_erasing
			_active_stamps = PackedVector2Array()
			_undo_stack.append(_image.duplicate())
			if _undo_stack.size() > 20:
				_undo_stack.pop_front()
			_append_stamps(_last_world_pos, _last_world_pos)
			queue_redraw()
		else:
			if _is_drawing:
				_commit_active_stroke()
				_active_stamps = PackedVector2Array()
				_is_drawing = false
				queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_undo()

	elif event is InputEventMouseMotion:
		var world_pos := _screen_to_world(event.position)
		_cursor_pos = world_pos
		if _is_drawing:
			var min_dist = max(1.0, _active_size * 0.35)
			if world_pos.distance_to(_last_world_pos) >= min_dist:
				_append_stamps(_last_world_pos, world_pos)
				_last_world_pos = world_pos
		queue_redraw()  # always redraw so cursor follows mouse

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Z:
				if event.ctrl_pressed: _undo()
			KEY_C:
				if event.ctrl_pressed: _clear_all()
			KEY_E:
				is_erasing = not is_erasing
			KEY_1: brush_type = "round"
			KEY_2: brush_type = "square"
			KEY_3: brush_type = "spray"
			KEY_EQUAL, KEY_KP_ADD:
				brush_size = min(brush_size + 2, 120)
			KEY_MINUS, KEY_KP_SUBTRACT:
				brush_size = max(brush_size - 2, 1)

# --- Stamp accumulation (for live _draw preview) ---

func _append_stamps(from: Vector2, to: Vector2) -> void:
	var dist := from.distance_to(to)
	var steps = max(int(dist / max(1.0, _active_size * 0.4)), 1)
	for s in steps:
		var t := float(s) / float(steps)
		var pos := from.lerp(to, t)
		if _active_type == "spray":
			for _i in _active_size * 3:
				var angle := randf() * TAU
				var d := randf() * _active_size
				_active_stamps.append(pos + Vector2(cos(angle), sin(angle)) * d)
		else:
			_active_stamps.append(pos)

# --- Commit: paint active stamps into the Image, upload once ---
# After this, the stroke costs nothing to display — it is just pixels in a texture.

func _commit_active_stroke() -> void:
	if _active_stamps.is_empty():
		return
	var color := Color(0, 0, 0, 0) if _active_erasing \
		else Color(_active_color.r, _active_color.g, _active_color.b, _active_opacity)
	for pos in _active_stamps:
		var px := _world_to_pixel(pos)
		if _active_erasing:
			_paint_square(px, _active_size + 10, color)  # eraser is always square for better coverage
		else:
			match _active_type:
				"round", "spray":
					_paint_circle(px, _active_size, color)
				"square":
					_paint_square(px, _active_size, color)
	_image_texture.update(_image)

# --- Pixel painters ---

func _paint_circle(center: Vector2i, radius: int, color: Color) -> void:
	var r2 := radius * radius
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x * x + y * y <= r2:
				_blend_pixel(center.x + x, center.y + y, color)

func _paint_square(center: Vector2i, half: int, color: Color) -> void:
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			_blend_pixel(center.x + x, center.y + y, color)

func _blend_pixel(x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= _canvas_pixel_size.x or y >= _canvas_pixel_size.y:
		return
	# Transparent color = eraser: always punch straight through
	if color.a == 0.0:
		_image.set_pixel(x, y, Color(0, 0, 0, 0))
	elif color.a >= 1.0:
		_image.set_pixel(x, y, color)
	else:
		var existing := _image.get_pixel(x, y)
		var blended := existing.lerp(color, color.a)
		blended.a = maxf(existing.a, color.a)
		_image.set_pixel(x, y, blended)

# --- Coordinate conversion ---

func _world_to_pixel(world_pos: Vector2) -> Vector2i:
	var local := world_pos + canvas_world_size * 0.5
	return Vector2i(
		int(local.x * pixels_per_unit),
		int(local.y * pixels_per_unit)
	)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

# --- _draw: ONLY the active stroke preview + cursor ---
# This is the key insight: no matter how much has been drawn historically,
# _draw() only ever touches the current stroke's stamps. Cost is O(active stroke length),
# NOT O(total drawing history).

func _draw() -> void:
	if _is_drawing and not _active_stamps.is_empty():
		var draw_color := Color(_active_color.r, _active_color.g, _active_color.b, _active_opacity)
		var radius := float(_active_size)
		match _active_type:
			"round", "spray":
				for pos in _active_stamps:
					draw_circle(pos, radius, draw_color)
			"square":
				var half := Vector2(_active_size, _active_size)
				var full := half * 2
				for pos in _active_stamps:
					draw_rect(Rect2(pos - half, full), draw_color)

	# Cursor ring — red when erasing, blue when drawing
	var cursor_color := Color(1.0, 0.3, 0.3, 0.85) if is_erasing else Color(0.2, 0.7, 1.0, 0.85)
	draw_arc(_cursor_pos, float(brush_size), 0.0, TAU, 32, cursor_color, 1.5)

# --- Undo / Clear ---

func _undo() -> void:
	if _undo_stack.is_empty():
		return
	_image = _undo_stack.pop_back()
	_image_texture.update(_image)
	queue_redraw()

func _clear_all() -> void:
	_undo_stack.append(_image.duplicate())
	_image.fill(Color(0, 0, 0, 0))
	_image_texture.update(_image)
	_active_stamps = PackedVector2Array()
	_is_drawing = false
	queue_redraw()

# --- Public API ---

func set_brush_color(color: Color) -> void: brush_color = color
func set_brush_size(size: int) -> void: brush_size = clamp(size, 1, 120)
func set_brush_type(type: String) -> void: brush_type = type
func set_opacity(value: float) -> void: opacity = clamp(value, 0.05, 1.0)
func set_erasing(erasing: bool) -> void: is_erasing = erasing
func undo() -> void: _undo()
func clear() -> void: _clear_all()

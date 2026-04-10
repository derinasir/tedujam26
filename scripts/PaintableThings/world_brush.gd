## WorldBrush.gd
## Add ONE of these as an AutoLoad or child of your scene root.
## It scans for PaintableSprite nodes and paints on them with mouse input.
## No UI required — just hold left click and paint in the world.

extends Node2D

# --- Brush Settings (tweak in Inspector or via code) ---
@export var brush_color: Color = Color.RED
@export var brush_size: int = 12          # radius in texture pixels
@export var brush_type: String = "round"  # "round" | "square" | "spray"
@export var opacity: float = 1.0          # 0.05 – 1.0
@export var is_erasing: bool = false

# --- Keyboard shortcuts (optional) ---
@export var key_round: Key = KEY_1
@export var key_square: Key = KEY_2
@export var key_spray: Key = KEY_3
@export var key_erase_toggle: Key = KEY_E
@export var key_clear_all: Key = KEY_C
@export var key_increase_size: Key = KEY_EQUAL
@export var key_decrease_size: Key = KEY_MINUS

# --- Cursor visual ---
var cursor: Node2D

var _painting := false
var _last_pos := Vector2.ZERO
var _paintable_sprites: Array[PaintableSprite] = []

func _ready() -> void:
	_build_cursor()
	call_deferred("_find_paintable_sprites")

func _find_paintable_sprites() -> void:
	_paintable_sprites.clear()
	_collect_paintable(get_tree().root)

func _collect_paintable(node: Node) -> void:
	if node is PaintableSprite:
		_paintable_sprites.append(node as PaintableSprite)
	for child in node.get_children():
		_collect_paintable(child)

# Call this at runtime if you add PaintableSprites dynamically
func register_sprite(ps: PaintableSprite) -> void:
	if not _paintable_sprites.has(ps):
		_paintable_sprites.append(ps)

func _input(event: InputEvent) -> void:
	# Mouse painting
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_painting = event.pressed
		if _painting:
			_last_pos = _world_mouse()
			_paint_at(_last_pos)

	elif event is InputEventMouseMotion:
		var world_pos := _world_mouse()
		_move_cursor(world_pos)
		if _painting:
			_stroke_to(world_pos)
			_last_pos = world_pos

	# Keyboard shortcuts
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			key_round:   brush_type = "round";  print("Brush: Round")
			key_square:  brush_type = "square"; print("Brush: Square")
			key_spray:   brush_type = "spray";  print("Brush: Spray")
			key_erase_toggle:
				is_erasing = not is_erasing
				print("Erasing: ", is_erasing)
			key_clear_all:
				for ps in _paintable_sprites:
					ps.clear()
			key_increase_size:
				brush_size = min(brush_size + 2, 80)
				_update_cursor()
			key_decrease_size:
				brush_size = max(brush_size - 2, 1)
				_update_cursor()

func _world_mouse() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam:
		return get_viewport().get_mouse_position() + cam.get_screen_center_position() - get_viewport().get_visible_rect().size * 0.5
	return get_viewport().get_mouse_position()

func _paint_at(world_pos: Vector2) -> void:
	for ps in _paintable_sprites:
		var pixel := ps.world_to_pixel(world_pos)
		if pixel.x >= 0:
			if is_erasing:
				ps.erase(pixel, brush_size)
			else:
				ps.paint(pixel, brush_size, brush_color, brush_type, opacity)

func _stroke_to(world_pos: Vector2) -> void:
	var dist := _last_pos.distance_to(world_pos)
	var steps := max(int(dist / 2.0), 1)  # stamp every 2 world units
	for i in steps:
		var t := float(i) / float(steps)
		_paint_at(_last_pos.lerp(world_pos, t))

# --- Cursor visual (circle that shows brush size in world space) ---
func _build_cursor() -> void:
	cursor = Node2D.new()
	add_child(cursor)

	var script := GDScript.new()
	script.source_code = """
extends Node2D
var brush_size := 12
var erasing := false
func _draw():
	var c = Color(0.2, 0.6, 1.0, 0.8) if not erasing else Color(1, 0.3, 0.3, 0.8)
	draw_arc(Vector2.ZERO, float(brush_size), 0, TAU, 32, c, 1.5)
"""
	cursor.set_script(script)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _move_cursor(world_pos: Vector2) -> void:
	cursor.position = world_pos
	cursor.set("erasing", is_erasing)
	cursor.queue_redraw()

func _update_cursor() -> void:
	cursor.set("brush_size", brush_size)
	cursor.queue_redraw()

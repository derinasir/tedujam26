extends TextureRect

# Canvas settings
var canvas_size := Vector2i(1280, 720)
var image: Image
var image_texture: ImageTexture

# Brush settings
var brush_color := Color.BLACK
var brush_size := 16
var brush_type := "round"  # "round", "square", "spray"
var is_erasing := false
var opacity := 1.0

# State
var is_drawing := false
var last_draw_pos := Vector2.ZERO

signal canvas_changed

func _ready() -> void:
	_init_canvas()
	set_process_input(true)

func _init_canvas() -> void:
	image = Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	image_texture = ImageTexture.create_from_image(image)
	texture = image_texture
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(canvas_size)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_drawing = event.pressed
			if is_drawing:
				last_draw_pos = _to_canvas_pos(event.position)
				_draw_brush(last_draw_pos)

	elif event is InputEventMouseMotion and is_drawing:
		var current_pos := _to_canvas_pos(event.position)
		_draw_line_between(last_draw_pos, current_pos)
		last_draw_pos = current_pos

func _to_canvas_pos(screen_pos: Vector2) -> Vector2:
	# Map screen position to canvas pixel coordinates
	var rect := get_global_rect()
	var local := screen_pos - rect.position
	var scale_x := canvas_size.x / rect.size.x
	var scale_y := canvas_size.y / rect.size.y
	return Vector2(local.x * scale_x, local.y * scale_y)

func _draw_line_between(from: Vector2, to: Vector2) -> void:
	var dist := from.distance_to(to)
	var steps: int = max(int(dist), 1)
	for i in steps:
		var t := float(i) / float(steps)
		var pos := from.lerp(to, t)
		_draw_brush(pos)
	image_texture.update(image)
	emit_signal("canvas_changed")

func _draw_brush(pos: Vector2) -> void:
	var color := Color.WHITE if is_erasing else Color(brush_color.r, brush_color.g, brush_color.b, opacity)
	var half := brush_size / 2

	match brush_type:
		"round":
			_draw_circle_brush(pos, half, color)
		"square":
			_draw_square_brush(pos, half, color)
		"spray":
			_draw_spray_brush(pos, half * 2, color)

	image_texture.update(image)
	emit_signal("canvas_changed")

func _draw_circle_brush(center: Vector2, radius: int, color: Color) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var px := int(center.x) + x
				var py := int(center.y) + y
				_set_pixel_blended(px, py, color)

func _draw_square_brush(center: Vector2, half: int, color: Color) -> void:
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var px := int(center.x) + x
			var py := int(center.y) + y
			_set_pixel_blended(px, py, color)

func _draw_spray_brush(center: Vector2, radius: int, color: Color) -> void:
	var density := brush_size * 3
	for _i in density:
		var angle := randf() * TAU
		var dist := randf() * radius
		var px := int(center.x + cos(angle) * dist)
		var py := int(center.y + sin(angle) * dist)
		_set_pixel_blended(px, py, color)

func _set_pixel_blended(x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= canvas_size.x or y >= canvas_size.y:
		return
	if color.a >= 1.0:
		image.set_pixel(x, y, color)
	else:
		var existing := image.get_pixel(x, y)
		var blended := existing.lerp(color, color.a)
		blended.a = 1.0
		image.set_pixel(x, y, blended)

func clear_canvas() -> void:
	image.fill(Color.WHITE)
	image_texture.update(image)
	emit_signal("canvas_changed")

func save_canvas(path: String = "user://drawing.png") -> void:
	image.save_png(path)
	print("Saved to: ", path)

func set_brush_color(color: Color) -> void:
	brush_color = color

func set_brush_size(size: int) -> void:
	brush_size = clamp(size, 1, 100)

func set_brush_type(type: String) -> void:
	brush_type = type

func set_erasing(erasing: bool) -> void:
	is_erasing = erasing

func set_opacity(value: float) -> void:
	opacity = clamp(value, 0.05, 1.0)

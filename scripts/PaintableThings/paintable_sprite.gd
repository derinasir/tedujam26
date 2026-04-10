## PaintableSprite.gd
## Attach this to a Sprite2D to make it paintable in world space.
## The brush paints directly onto the sprite's texture at runtime.

extends Sprite2D

@export var texture_width: int = 256
@export var texture_height: int = 256
@export var base_color: Color = Color.WHITE

var image: Image
var image_texture: ImageTexture

func _ready() -> void:
	_bake_texture()

func _bake_texture() -> void:
	# If the sprite already has a texture, bake it into a paintable image
	if texture and not texture is ImageTexture:
		var src: Image = texture.get_image()
		image = src.duplicate()
		image.convert(Image.FORMAT_RGBA8)
	else:
		image = Image.create(texture_width, texture_height, false, Image.FORMAT_RGBA8)
		image.fill(base_color)

	image_texture = ImageTexture.create_from_image(image)
	texture = image_texture

## Convert a world-space position to pixel coordinates on this sprite's image.
## Returns Vector2(-1, -1) if the point is outside the sprite bounds.
func world_to_pixel(world_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = to_local(world_pos)
	var tex_size := Vector2(image.get_width(), image.get_height())
	var sprite_size := tex_size * scale  # visual size in local space

	# Sprite2D origin is centered
	var uv := (local_pos / sprite_size) + Vector2(0.5, 0.5)

	if uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1:
		return Vector2i(-1, -1)

	return Vector2i(int(uv.x * tex_size.x), int(uv.y * tex_size.y))

func paint(pixel: Vector2i, brush_size: int, color: Color, brush_type: String, opacity: float) -> void:
	if pixel.x < 0:
		return

	var paint_color := Color(color.r, color.g, color.b, opacity)
	var half := brush_size

	match brush_type:
		"round":
			for x in range(-half, half + 1):
				for y in range(-half, half + 1):
					if x * x + y * y <= half * half:
						_blend_pixel(pixel.x + x, pixel.y + y, paint_color)
		"square":
			for x in range(-half, half + 1):
				for y in range(-half, half + 1):
					_blend_pixel(pixel.x + x, pixel.y + y, paint_color)
		"spray":
			for _i in brush_size * 4:
				var angle := randf() * TAU
				var dist := randf() * half
				_blend_pixel(
					pixel.x + int(cos(angle) * dist),
					pixel.y + int(sin(angle) * dist),
					paint_color
				)

	image_texture.update(image)

func erase(pixel: Vector2i, brush_size: int) -> void:
	if pixel.x < 0:
		return
	var half := brush_size
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			if x * x + y * y <= half * half:
				_set_pixel(pixel.x + x, pixel.y + y, base_color)
	image_texture.update(image)

func _blend_pixel(x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	if color.a >= 1.0:
		image.set_pixel(x, y, color)
	else:
		var existing := image.get_pixel(x, y)
		var blended := existing.lerp(color, color.a)
		blended.a = 1.0
		image.set_pixel(x, y, blended)

func _set_pixel(x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, color)

func clear() -> void:
	image.fill(base_color)
	image_texture.update(image)

func save(path: String) -> void:
	image.save_png(path)

extends PointLight2D 
@export var player: Player

func create_cone_texture(radius: int, angle_deg: float) -> ImageTexture:
	var img := Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	var half_angle := deg_to_rad(angle_deg * 0.5)
	
	for x in radius * 2:
		for y in radius * 2:
			var pos := Vector2(x, y) - center
			var dist := pos.length()
			var pixel_angle = abs(pos.angle())  # angle from pointing right
			
			if dist <= radius and pixel_angle <= half_angle:
				var falloff := 1.0 - (dist / radius)
				img.set_pixel(x, y, Color(1, 1, 1, falloff))
	
	return ImageTexture.create_from_image(img)
	
func _ready() -> void:
	var cone_texture: ImageTexture = create_cone_texture(128, 60)
	texture = cone_texture
	
func _process(delta: float) -> void:
	# var direction := player.last_input_direction
	# var target_angle: float = direction.angle()
	rotation = lerp_angle(rotation, player.pivot.rotation, (player.ROTATION_SPEED * 10) * delta)

extends Node2D

@export var ray_count: int = 8
@export var spread_angle: float = 90.0
@export var ray_length: float = 400.0
@export var sonar_angle: float = 60.0
@export_group("SFX Resources")
@export var sfx_sonar_ping: AudioStream
@export var sfx_fuel: AudioStream
@export var sfx_enemy: AudioStream
@export var sfx_wall: AudioStream
@export var sfx_void: AudioStream
@export_group("Settings")
@export var feedback_delay: float = 0.5
@export var cooldown_time: float = 4.0

var sonar_dots: Array[SonarDot] = []
var _can_sonar: bool = true


func _ready() -> void:
	GameEvents.sonar_detected.connect(_on_sonar_detected)
	create_rays()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("send_sonar_wave") and _can_sonar:
		execute_sonar()


func create_rays() -> void:
	for child in get_children():
		child.queue_free()

	var start_angle = -spread_angle / 2.0
	var angle_step = 0.0

	if ray_count > 1:
		angle_step = spread_angle / (ray_count - 1)

	for i in range(ray_count):
		var ray = RayCast2D.new()
		var current_angle = deg_to_rad(start_angle + (i * angle_step))

		ray.target_position = Vector2.UP.rotated(current_angle) * ray_length
		ray.enabled = true
		ray.collision_mask = 8
		ray.collide_with_areas = true
		add_child(ray)


func execute_sonar() -> void:
	_can_sonar = false

	if sfx_sonar_ping:
		SFXManager.play_sfx(sfx_sonar_ping)

	var start_angle = -sonar_angle / 2.0
	var angle_step = 0.0

	if ray_count > 1:
		angle_step = sonar_angle / (ray_count - 1)

	var rays = get_children()
	var detected_objects: Array[Node] = []

	for i in range(rays.size()):
		var ray = rays[i] as RayCast2D
		if not ray:
			continue

		var original_pos = ray.target_position
		var sonar_rad = deg_to_rad(start_angle + (i * angle_step))
		ray.target_position = Vector2.UP.rotated(sonar_rad) * ray_length

		ray.force_raycast_update()

		if ray.is_colliding():
			var object := ray.get_collider()
			var new_dot = SonarDot.new(ray.get_collision_point(), object.get_groups()[0])
			sonar_dots.append(new_dot)
			if not detected_objects.has(object):
				detected_objects.append(object)

		ray.target_position = original_pos

	start_cooldown()
	await get_tree().create_timer(feedback_delay).timeout
	process_detected_objects(detected_objects)

	GameEvents.request_draw_dot.emit(sonar_dots)
	sonar_dots.clear()


func start_cooldown() -> void:
	await get_tree().create_timer(cooldown_time).timeout
	_can_sonar = true


func process_detected_objects(objects: Array[Node]) -> void:
	var highest_priority: int = 999
	var target_group: String = ""

	if objects.is_empty():
		target_group = "void"
	else:
		for object in objects:
			for group in object.get_groups():
				if Constants.group_data.has(group):
					var priority: int = Constants.group_data[group]["priority"]
					if priority < highest_priority:
						highest_priority = priority
						target_group = group

		if target_group == "":
			target_group = "void"

	var data = Constants.group_data[target_group]
	GameEvents.sonar_detected.emit(target_group, data)


func _on_sonar_detected(group_name: String, data: Dictionary) -> void:
	var stream: AudioStream
	match group_name:
		"fuel_pack":
			stream = sfx_fuel
		"enemy":
			stream = sfx_void
		"wall":
			stream = sfx_wall
		"void":
			stream = sfx_void
		_:
			stream = sfx_void
			print("sonar.gd: no stream matched")

	SFXManager.play_sfx(stream)
	print("Feedback: ", group_name)

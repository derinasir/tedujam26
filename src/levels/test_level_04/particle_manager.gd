extends Node2D

const SPARKS = preload("uid://tuppry3imiu2")
const BUBBLES = preload("uid://dugme0ugsx4yc")
const FIH = preload("uid://0mj10y7qcuh1")
const TIME_MIN = 2.0
const TIME_MAX = 5.0
const OFFSET_MIN = 150.0
const OFFSET_MAX = 400.0
const FISH_MOVE_DISTANCE = 200.0

@export var player: Player

var sparks_instance: Node2D = null


func _ready() -> void:
	GameEvents.wall_friction_started.connect(_on_wall_friction_started)
	GameEvents.wall_friction_ended.connect(_on_wall_friction_ended)
	GameEvents.wall_friction_updated.connect(_on_wall_friction_updated)
	_main_loop()


func _main_loop() -> void:
	while true:
		await get_tree().create_timer(randf_range(TIME_MIN, TIME_MAX)).timeout
		if not is_instance_valid(player):
			continue

		var chance = randf()
		if chance < 0.45:
			_spawn_bubbles()
		elif chance < 0.90:
			_spawn_fish()
		else:
			_spawn_bubbles()
			_spawn_fish()


func _spawn_bubbles() -> void:
	var bubble = BUBBLES.instantiate()
	add_child(bubble)
	bubble.global_position = player.global_position + _get_random_offset()
	bubble.emitting = true
	bubble.finished.connect(bubble.queue_free)


func _spawn_fish() -> void:
	var fish = FIH.instantiate()
	add_child(fish)

	var start_pos = player.global_position + _get_random_offset()
	var random_direction = Vector2.UP.rotated(randf_range(0, TAU))
	var target_pos = start_pos + (random_direction * FISH_MOVE_DISTANCE)

	fish.global_position = start_pos
	fish.rotation = random_direction.angle() + PI / 2

	var tween = create_tween()
	tween.tween_property(fish, "global_position", target_pos, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fish.queue_free)


func _get_random_offset() -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(OFFSET_MIN, OFFSET_MAX)
	return Vector2.from_angle(angle) * distance


func _on_wall_friction_updated(global_pos: Vector2, _normal: Vector2, direction: Vector2) -> void:
	if sparks_instance != null and sparks_instance.emitting:
		sparks_instance.global_position = global_pos
		sparks_instance.rotation = (-direction).angle()


func _on_wall_friction_started(global_pos: Vector2, _normal: Vector2, direction: Vector2) -> void:
	if sparks_instance == null:
		sparks_instance = SPARKS.instantiate()
		add_child(sparks_instance)
	sparks_instance.global_position = global_pos
	sparks_instance.rotation = (-direction).angle()
	sparks_instance.emitting = true


func _on_wall_friction_ended() -> void:
	if sparks_instance != null:
		sparks_instance.emitting = false

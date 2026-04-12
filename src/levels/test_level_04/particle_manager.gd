extends Node2D

const SPARKS = preload("uid://tuppry3imiu2")
const BUBBLES = preload("uid://dugme0ugsx4yc")
const BUBBLE_TIME_MIN = 5.0
const BUBBLE_TIME_MAX = 10.0
const BUBBLE_OFFSET_RANGE = 350.0

@export var player: Player

var sparks_instance: Node2D = null


func _ready() -> void:
	GameEvents.wall_friction_started.connect(_on_wall_friction_started)
	GameEvents.wall_friction_ended.connect(_on_wall_friction_ended)
	GameEvents.wall_friction_updated.connect(_on_wall_friction_updated)

	_bubble_loop()


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


func _bubble_loop() -> void:
	while true:
		await get_tree().create_timer(randf_range(BUBBLE_TIME_MIN, BUBBLE_TIME_MAX)).timeout

		if is_instance_valid(player):
			var bubble = BUBBLES.instantiate()
			add_child(bubble)

			var random_offset = Vector2(
				randf_range(-BUBBLE_OFFSET_RANGE, BUBBLE_OFFSET_RANGE),
				randf_range(-BUBBLE_OFFSET_RANGE, BUBBLE_OFFSET_RANGE),
			)
			bubble.global_position = player.global_position + random_offset

			bubble.emitting = true
			bubble.finished.connect(bubble.queue_free)

extends Node2D

const SPARKS = preload("uid://tuppry3imiu2")

var sparks_instance: Node2D = null


func _ready() -> void:
	GameEvents.wall_friction_started.connect(_on_wall_friction_started)
	GameEvents.wall_friction_ended.connect(_on_wall_friction_ended)


func _on_wall_friction_started(global_pos: Vector2, _normal: Vector2, direction: Vector2) -> void:
	if sparks_instance == null:
		sparks_instance = SPARKS.instantiate()
		add_child(sparks_instance)

	sparks_instance.global_position = global_pos
	sparks_instance.rotation = (-direction).angle()

	if not sparks_instance.emitting:
		sparks_instance.emitting = true


func _on_wall_friction_ended() -> void:
	if sparks_instance != null:
		sparks_instance.emitting = false

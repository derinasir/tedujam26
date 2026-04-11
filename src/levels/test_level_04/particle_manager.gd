extends Node2D

const SPARKS = preload("uid://tuppry3imiu2")

@export var player: Player

var sparks_instance: Node2D = null


func _ready() -> void:
	GameEvents.wall_friction_started.connect(_on_wall_friction_started)
	GameEvents.wall_friction_ended.connect(_on_wall_friction_ended)
	GameEvents.wall_friction_updated.connect(_on_wall_friction_updated)


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

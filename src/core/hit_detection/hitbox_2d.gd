class_name Hitbox2D
extends Area2D

@warning_ignore("unused_signal")
signal struck(id: int, hit_info: HitInfo)

@export var root: Node2D

var active: bool = false
var id: int
var hit_info: HitInfo

@onready var colshape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	id = randi()
	area_entered.connect(_on_area_entered)


func activate() -> void:
	active = true
	monitorable = true
	colshape.disabled = false


func deactivate() -> void:
	active = false
	monitorable = false
	colshape.disabled = true


@warning_ignore("unused_parameter")
func _on_area_entered(area: Area2D) -> void:
	pass

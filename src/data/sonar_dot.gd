class_name SonarDot
extends RefCounted

var global_position: Vector2 = Vector2.ZERO
var color: Color
var group: String


func _init(p_global_pos: Vector2, p_group: String) -> void:
	global_position = p_global_pos
	group = p_group

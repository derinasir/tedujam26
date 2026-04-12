extends Node2D

var lights: Array[PointLight2D]


func _ready() -> void:
	GameEvents.sonar_sent.connect(_on_sonar_sent)
	GameEvents.sonar_detected.connect(_on_sonar_detected)

	for child in get_children():
		if child is PointLight2D:
			lights.append(child)


func _on_sonar_sent(_direction: Vector2, _feedback_delay: float) -> void:
	for light in lights:
		light.enabled = true


func _on_sonar_detected(_group_name: String, _data: Dictionary) -> void:
	for light in lights:
		light.enabled = false

extends Sprite2D


func _ready() -> void:
	GameEvents.sonar_sent.connect(_on_sonar_sent)


func send_wave(feedback_delay: float):
	var tween = create_tween()
	material.set_shader_parameter("spread", 0.0)

	tween.tween_property(material, "shader_parameter/spread", 1.0, feedback_delay)

	await tween.finished
	material.set_shader_parameter("spread", 0.0)


func _on_sonar_sent(direction: Vector2, feedback_delay: float) -> void:
	material.set_shader_parameter("direction", direction.normalized())
	send_wave(feedback_delay)

extends Node2D

var _sonar_dots: Array[SonarDot] = []


func _ready() -> void:
	GameEvents.request_draw_dot.connect(_on_request_draw_dots)


func _process(delta: float) -> void:
	if _sonar_dots.is_empty():
		return

	var i = _sonar_dots.size() - 1
	while i >= 0:
		var dot = _sonar_dots[i]
		dot.lifetime -= delta

		if dot.lifetime <= 0:
			_sonar_dots.remove_at(i)
		else:
			dot.color.a = dot.lifetime / dot.max_lifetime

		i -= 1

	queue_redraw()


func _draw() -> void:
	for dot: SonarDot in _sonar_dots:
		draw_circle(to_local(dot.global_position), 5.0, dot.color)


func match_group_color(group_name: String) -> Color:
	var color: Color
	match group_name:
		"fuel_pack":
			color = Color(4.416, 4.416, 0.0)
		"enemy":
			color = Color(1.808, 0.0, 0.0)
		"wall":
			color = Color(4.416, 4.416, 4.416)
		"void":
			color = Color(Color.BLACK, 0.0)
		_:
			color = Color.WHITE
	return color


func _on_request_draw_dots(sonar_dots: Array[SonarDot]):
	for dot in sonar_dots:
		dot.color = match_group_color(dot.group)
		_sonar_dots.append(dot)
	queue_redraw()

extends Node2D

var dots_changed: bool = false
var _sonar_dots: Array[SonarDot] = []


func _ready() -> void:
	GameEvents.request_draw_dot.connect(_on_request_draw_dots)


func _draw():
	if dots_changed:
		for dot: SonarDot in _sonar_dots:
			draw_circle(to_local(dot.global_position), 5.0, dot.color)
	dots_changed = false


func match_group_color(group_name: String) -> Color:
	var color: Color
	match group_name:
		"fuel_pack":
			color = Color.YELLOW
		"enemy":
			color = Color.DARK_RED
		"wall":
			color = Color.BROWN
		"void":
			color = Color(Color.BLACK, 0.0)
		_:
			color = Color.WHITE

	return color


func _on_request_draw_dots(sonar_dots: Array[SonarDot]):
	for dot in sonar_dots:
		dot.color = match_group_color(dot.group)
	_sonar_dots = sonar_dots.duplicate()
	dots_changed = true
	queue_redraw()

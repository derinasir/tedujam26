extends Node2D
var hitpoints: Array = []
var hitpoints_changed: bool = false
func _ready() -> void:
	GameEvents.request_draw_dot.connect(_on_request_draw_dots)
func _draw():
	if hitpoints_changed:
		for hit: Vector2 in hitpoints:
			draw_circle(to_local(hit), 5.0, Color.WHITE)
			print(to_local(hit), "asdasddasdas", hit)
		
	hitpoints_changed = false
	
func _on_request_draw_dots(positions: Array[Vector2]):
	hitpoints = positions
	hitpoints_changed = true
	queue_redraw()
	
func _fade_out_dot(dots: Array[Vector2]):
	for 
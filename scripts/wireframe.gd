extends Node2D
func _draw():
	draw_circle(Vector2(0,0), 10, Color.AQUA)
	queue_redraw()
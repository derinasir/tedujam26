## ColliderWireframe.gd
## Attach to any node that has a CollisionShape2D child.
## Draws the shape as a wireframe on top of the node.

extends Node2D

@export var color: Color = Color(0.0, 1.0, 0.4, 1.0)
@export var line_width: float = 1.5
@export var segments_per_curve: int = 32

@onready var col: CollisionShape2D = _find_shape(self)

func _find_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
	return null
	
func _draw() -> void:
	if col == null or col.shape == null:
		return
		
	var shape := col.shape
	var offset := to_local(col.global_position)
	var rot := col.rotation
	
	if shape is RectangleShape2D:
		var e: Vector2 = shape.size * 0.5
		var pts := _rotated([
			Vector2(-e.x, -e.y), Vector2(e.x, -e.y),
			Vector2(e.x, e.y),   Vector2(-e.x, e.y)
		], rot, offset)
		_draw_polygon_lines(pts)
		
	elif shape is CircleShape2D:
		draw_arc(offset, shape.radius, 0.0, TAU, segments_per_curve, color, line_width)
		
	elif shape is CapsuleShape2D:
		var pts := _rotated(_capsule_points(shape.radius, shape.height), rot, offset)
		_draw_polygon_lines(pts)
		
	elif shape is ConvexPolygonShape2D:
		var pts := _rotated(Array(shape.points), rot, offset)
		_draw_polygon_lines(pts)
		
	elif shape is ConcavePolygonShape2D:
		var raw: PackedVector2Array = shape.segments
		var i := 0
		while i + 1 < raw.size():
			var a := _xform(raw[i],     rot, offset)
			var b := _xform(raw[i + 1], rot, offset)
			draw_line(a, b, color, line_width, true)
			i += 2
			
	elif shape is SegmentShape2D:
		draw_line(_xform(shape.a, rot, offset), _xform(shape.b, rot, offset), color, line_width, true)
		
func _draw_polygon_lines(pts: Array) -> void:
	for i in pts.size():
		draw_line(pts[i], pts[(i + 1) % pts.size()], color, line_width, true)
		
func _rotated(pts: Array, rot: float, offset: Vector2) -> Array:
	return pts.map(func(p): return _xform(p, rot, offset))
	
func _xform(p: Vector2, rot: float, offset: Vector2) -> Vector2:
	return p.rotated(rot) + offset
	
func _capsule_points(radius: float, height: float) -> Array:
	var half_h := maxf((height * 0.5) - radius, 0.0)
	var pts := []
	var half := segments_per_curve / 2
	for i in range(half + 1):
		var a := PI + PI * float(i) / float(half)
		pts.append(Vector2(cos(a) * radius, sin(a) * radius - half_h))
	for i in range(half + 1):
		var a := PI * float(i) / float(half)
		pts.append(Vector2(cos(a) * radius, sin(a) * radius + half_h))
	return pts
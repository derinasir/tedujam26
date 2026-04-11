## ColliderWireframe.gd
## Attach to any Node2D that has a CollisionShape2D child.
## Draws the collider's wireframe visible only within a radius from an origin point.
## Everything outside the radius is clipped — not drawn at all.
##
## Supports: RectangleShape2D, CircleShape2D, CapsuleShape2D, ConvexPolygonShape2D,
##           ConcavePolygonShape2D, SegmentShape2D, SeparationRayShape2D
##
## Scene setup:
##   Node2D  ← attach this script
##   └── CollisionShape2D

extends Node2D

# --- Settings ---
@export var wireframe_color: Color = Color(0.0, 1.0, 0.4, 1.0)
@export var line_width: float = 1.5
@export var reveal_radius: float = 120.0        # world-unit radius around origin_point
@export var origin_point: Vector2 = Vector2.ZERO # world position of the reveal center
@export var segments_per_curve: int = 32         # smoothness for circles/capsules

# Which CollisionShape2D to read. Auto-detected if left empty.
@export var target_shape: CollisionShape2D = null

func _ready() -> void:
	z_index = 50
	if target_shape == null:
		target_shape = _find_collision_shape(self)
	if target_shape == null:
		push_warning("ColliderWireframe: no CollisionShape2D found.")

func _find_collision_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
	return null

# Call this from outside to move the reveal origin (e.g. follow mouse or player)
func set_origin(world_pos: Vector2) -> void:
	origin_point = world_pos
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if target_shape == null or target_shape.shape == null:
		return

	# Build the wireframe as a list of world-space line segments
	var segments := _shape_to_segments(target_shape)

	# Clip each segment to the reveal radius and draw
	for seg in segments:
		var clipped := _clip_segment_to_circle(seg[0], seg[1], origin_point, reveal_radius)
		if clipped.is_empty():
			continue
		# Convert world positions to local space for draw_line
		var a := to_local(clipped[0])
		var b := to_local(clipped[1])
		draw_line(a, b, wireframe_color, line_width, true)

# --- Shape → world-space segments ---

func _shape_to_segments(col: CollisionShape2D) -> Array:
	var shape := col.shape
	var xform := col.global_transform  # shape's own transform (position + rotation)
	var segs: Array = []

	if shape is RectangleShape2D:
		var e: Vector2 = shape.size * 0.5
		var corners := [
			Vector2(-e.x, -e.y), Vector2( e.x, -e.y),
			Vector2( e.x,  e.y), Vector2(-e.x,  e.y)
		]
		_polygon_to_segments(corners, xform, segs)

	elif shape is CircleShape2D:
		var pts := _circle_points(Vector2.ZERO, shape.radius, segments_per_curve)
		_polygon_to_segments(pts, xform, segs)

	elif shape is CapsuleShape2D:
		var pts := _capsule_points(shape.radius, shape.height, segments_per_curve)
		_polygon_to_segments(pts, xform, segs)

	elif shape is ConvexPolygonShape2D:
		_polygon_to_segments(shape.points, xform, segs)

	elif shape is ConcavePolygonShape2D:
		# ConcavePolygon stores raw triangle segments: [a, b, b, c, c, a, ...]
		var pts: PackedVector2Array = shape.segments
		var i := 0
		while i + 1 < pts.size():
			segs.append([xform * pts[i], xform * pts[i + 1]])
			i += 2

	elif shape is SegmentShape2D:
		segs.append([xform * shape.a, xform * shape.b])

	elif shape is SeparationRayShape2D:
		segs.append([xform * Vector2.ZERO, xform * Vector2(0, shape.length)])

	return segs

func _polygon_to_segments(points: Array, xform: Transform2D, out: Array) -> void:
	var n := points.size()
	for i in n:
		var a: Vector2 = xform * Vector2(points[i])
		var b: Vector2 = xform * Vector2(points[(i + 1) % n])
		out.append([a, b])

func _circle_points(center: Vector2, radius: float, count: int) -> Array:
	var pts := []
	for i in count:
		var angle := TAU * float(i) / float(count)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts

func _capsule_points(radius: float, height: float, count: int) -> Array:
	var half_h := (height * 0.5) - radius
	half_h = max(half_h, 0.0)
	var pts := []
	var half := count / 2
	# Top semicircle
	for i in range(half + 1):
		var angle := PI + PI * float(i) / float(half)
		pts.append(Vector2(cos(angle) * radius, sin(angle) * radius - half_h))
	# Bottom semicircle
	for i in range(half + 1):
		var angle := PI * float(i) / float(half)
		pts.append(Vector2(cos(angle) * radius, sin(angle) * radius + half_h))
	return pts

# --- Clip a line segment to a circle (Cohen–Sutherland style parametric clip) ---
# Returns [] if fully outside, or [Vector2, Vector2] if any part is inside.

func _clip_segment_to_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> Array:
	var la := a - center
	var lb := b - center
	var r2 := radius * radius
	var da := la.length_squared()
	var db := lb.length_squared()
	var a_in := da <= r2
	var b_in := db <= r2

	if a_in and b_in:
		return [a, b]

	# Find intersection(s) of segment with circle
	# Parametric: P(t) = la + t*(lb-la), solve |P(t)|^2 = r^2
	var d := lb - la
	var A := d.dot(d)
	var B := 2.0 * la.dot(d)
	var C := la.dot(la) - r2
	var disc := B * B - 4.0 * A * C

	if disc < 0.0 or A == 0.0:
		return []  # no intersection

	var sq := sqrt(disc)
	var t1 := (-B - sq) / (2.0 * A)
	var t2 := (-B + sq) / (2.0 * A)

	# Clamp intersection params to [0,1] (segment bounds)
	var t_enter := clampf(t1, 0.0, 1.0)
	var t_exit  := clampf(t2, 0.0, 1.0)

	if t_enter >= t_exit:
		return []

	var p_enter := a + (b - a) * t_enter
	var p_exit  := a + (b - a) * t_exit

	# If one endpoint is inside, use it directly (avoids floating point drift)
	var clip_a := a if a_in else p_enter
	var clip_b := b if b_in else p_exit

	return [clip_a, clip_b]
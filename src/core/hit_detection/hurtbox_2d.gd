class_name Hurtbox2D
extends Area2D

@warning_ignore("unused_signal")
signal was_hit(id: int, hit_info: HitInfo)

@export var debug: bool = false
@export var activate_on_ready: bool = false
@export var ignore_self: bool = true
@export var root: Node2D
@export var hit_masks: Array[StringName]

var active: bool = false
var id: int

@onready var colshape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	id = randi()
	area_entered.connect(_on_area_entered)

	if activate_on_ready:
		activate()


func activate() -> void:
	active = true
	monitoring = true
	colshape.disabled = false


func deactivate() -> void:
	active = false
	monitoring = false
	colshape.disabled = true


func _on_area_entered(area: Area2D) -> void:
	if not area is Hitbox2D:
		return

	if not area.is_in_group("hitbox"):
		return

	if ignore_self and (owner == area.owner):
		return

	if not area.hit_info:
		print("Hitbox has no injected HitInfo")
		return

	if debug:
		print("area entered, area id: " + str(area.id))

	var allowed: bool = false
	for mask in hit_masks:
		if mask == "hitbox":
			continue
		if area.is_in_group(mask):
			allowed = true
			break

	if not allowed:
		return

	var hit_info: HitInfo = area.hit_info.clone()

	var knockback_dir: Vector2 = root.global_position - area.root.global_position
	var alignment = Vector2.RIGHT.dot(knockback_dir)

	hit_info.knockback_dir = knockback_dir
	hit_info.alignment = alignment
	hit_info.victim = root

	was_hit.emit(id, hit_info)
	area.struck.emit(area.id, hit_info)

	if debug:
		print("Hurtbox was hit, attacker id: " + str(id))

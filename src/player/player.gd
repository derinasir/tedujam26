class_name Player
extends CharacterBody2D

signal wall_friction_started(global_pos: Vector2, normal: Vector2)
signal wall_friction_ended

const FORCE: float = 100.0
const THRUSTER_FORCE: float = 400.0
const FRICTION: float = 2.0
const BRAKE_FORCE: float = 5.0
const VELOCITY_CAP: float = 400.0

@export_group("Settings")
@export_range(0.0, 1.0) var WALL_FRICTION: float = 0.7
@export var MIN_FRICTION_SPEED: float = 50.0
@export var ROTATION_SPEED: float = 10.0
@export var THRUST_FADE_SPEED: float = 5.0
@export var maxHealth: float = 100.0

var health: float
var is_thruster_on: bool = false
var is_fricting_walls: bool = false
var last_input_direction: Vector2 = Vector2.UP

@onready var pivot: Node2D = $Pivot
@onready var thrust_player: AudioStreamPlayer = $ThrustAudioPlayer


func _ready() -> void:
	health = maxHealth


func _process(_delta: float) -> void:
	is_thruster_on = Input.is_action_pressed("thruster")


func _physics_process(delta: float) -> void:
	# var input_dir = Input.get_vector(
	# 	"move_left",
	# 	"move_right",
	# 	"move_up",
	# 	"move_down",
	# )
	var horizontal_input: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var vertical_input: float = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	# handle_movement(input_dir, delta)
	# handle_rotation(input_dir, delta)
	handle_movement(vertical_input, delta)
	handle_rotation(horizontal_input, delta)
	handle_thrust_audio(delta)

	move_and_slide()
	handle_wall_friction(delta)


func handle_movement(input_dir: float, delta: float) -> void:
	# Push along whichever way the pivot is currently facing
	var facing := Vector2.RIGHT.rotated(pivot.rotation)

	if input_dir != 0:
		var final_force := THRUSTER_FORCE if is_thruster_on else FORCE
		var move_vec := (facing * input_dir) * -1

		if velocity.length() > 0 and move_vec.dot(velocity.normalized()) < 0:
			velocity = velocity.move_toward(Vector2.ZERO, final_force * BRAKE_FORCE * delta)

		velocity += move_vec * final_force * delta

		if not is_thruster_on:
			velocity = velocity.limit_length(VELOCITY_CAP)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FORCE * FRICTION * delta)


func handle_rotation(input_dir: float, delta: float) -> void:
	pivot.rotation += input_dir * ROTATION_SPEED * delta


# func handle_movement(input_dir: Vector2, delta: float) -> void:
# 	if input_dir != Vector2.ZERO:
# 		var final_force = THRUSTER_FORCE if is_thruster_on else FORCE
#
# 		if velocity.length() > 0 and input_dir.dot(velocity.normalized()) < 0:
# 			velocity = velocity.move_toward(Vector2.ZERO, final_force * BRAKE_FORCE * delta)
#
# 		velocity += input_dir * final_force * delta
#
# 		if not is_thruster_on:
# 			velocity = velocity.limit_length(VELOCITY_CAP)
# 	else:
# 		velocity = velocity.move_toward(Vector2.ZERO, FORCE * FRICTION * delta)
# func handle_rotation(input_dir: Vector2, delta: float) -> void:
# 	if input_dir != Vector2.ZERO:
# 		last_input_direction = input_dir
#
# 	var target_angle = last_input_direction.angle()
# 	pivot.rotation = lerp_angle(pivot.rotation, target_angle, ROTATION_SPEED * delta)
func handle_thrust_audio(delta: float) -> void:
	var is_moving = velocity.length() > 10.0
	var target_volume = 0.0 if (is_thruster_on and is_moving) else -80.0

	thrust_player.volume_db = lerp(thrust_player.volume_db, target_volume, THRUST_FADE_SPEED * delta)

	if target_volume > -80.0 and not thrust_player.playing:
		thrust_player.play()
	elif thrust_player.volume_db <= -70.0 and thrust_player.playing:
		thrust_player.stop()

	var target_pitch = 1.0 + (velocity.length() / VELOCITY_CAP) * 0.3
	thrust_player.pitch_scale = lerp(thrust_player.pitch_scale, target_pitch, delta * 2.0)


func handle_wall_friction(_delta: float) -> void:
	var current_friction_state: bool = false

	if get_slide_collision_count() > 0 and velocity.length() > MIN_FRICTION_SPEED:
		velocity = velocity.lerp(Vector2.ZERO, WALL_FRICTION * 0.1)

		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var normal = collision.get_normal()
			var point = collision.get_position()

			if velocity.dot(normal) < 0:
				velocity = velocity.slide(normal) * (1.0 - WALL_FRICTION)
				print("Friction started")
				wall_friction_started.emit(point, normal)
				current_friction_state = true

	if is_fricting_walls and not current_friction_state:
		wall_friction_ended.emit()

	is_fricting_walls = current_friction_state


func get_hurt(damage: float) -> void:
	health -= damage
	if health <= 0:
		GameEvents.player_died.emit()
	pass

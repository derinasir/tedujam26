class_name Player
extends CharacterBody2D

const FORCE: float = 100.0
const THRUSTER_FORCE: float = 400.0
const FRICTION: float = 2.0
const BRAKE_FORCE: float = 5.0
const VELOCITY_CAP: float = 400.0
const FRICTION_BUFFER_TIME: float = 0.15

@export_group("Settings")
@export_range(0.0, 1.0) var WALL_FRICTION: float = 0.7
@export var MIN_FRICTION_SPEED: float = 50.0
@export var ROTATION_SPEED: float = 10.0
@export var THRUST_FADE_SPEED: float = 5.0
@export var maxHealth: float = 100.0
@export var damageFromWallFriction: float = 10.0
@export var maxEnergy: float = 100.0
@export var energyConsumptionRate: float = 20.0
@export var maxOxygen: float = 100.0

var energy: float
var health: float
var oxygen: float
var is_thruster_on: bool = false
var is_fricting_walls: bool = false
var last_input_direction: Vector2 = Vector2.UP
var friction_buffer_timer: float = 0.0
var smoothed_friction_point: Vector2 = Vector2.ZERO
var smoothed_friction_normal: Vector2 = Vector2.ZERO
var friction_pos: Vector2 = Vector2.ZERO

@onready var pivot: Node2D = $Pivot
@onready var friction_stream_player: AudioStreamPlayer = $FrictionStreamPlayer
@onready var thrust_player: AudioStreamPlayer = $ThrustAudioPlayer


func _ready() -> void:
	health = maxHealth
	energy = maxEnergy
	oxygen = maxOxygen
	GameEvents.player_picked_fuel.connect(_on_player_picked_fuel)
	GameEvents.wall_friction_started.connect(_on_wall_friction_started)
	GameEvents.wall_friction_ended.connect(_on_wall_friction_ended)


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
			energy -= energyConsumptionRate * delta
			GameEvents.player_energy_changed.emit()
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


func handle_wall_friction(delta: float) -> void:
	var was_fricting = is_fricting_walls
	var collision_detected: bool = false

	var best_collision_point := Vector2.ZERO
	var best_collision_normal := Vector2.ZERO

	if get_slide_collision_count() > 0 and velocity.length() > MIN_FRICTION_SPEED:
		var max_penetration := -1.0
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var normal = collision.get_normal()
			var penetration = collision.get_depth()

			if velocity.dot(normal) < -0.1:
				collision_detected = true
				if penetration > max_penetration:
					max_penetration = penetration
					best_collision_point = collision.get_position()
					best_collision_normal = normal

		if collision_detected:
			var target_velocity = velocity.slide(best_collision_normal) * (1.0 - WALL_FRICTION)
			velocity = velocity.move_toward(target_velocity, WALL_FRICTION * velocity.length() * delta * 5.0)

	if collision_detected:
		friction_buffer_timer = FRICTION_BUFFER_TIME
		is_fricting_walls = true

		if smoothed_friction_point == Vector2.ZERO:
			smoothed_friction_point = best_collision_point
			smoothed_friction_normal = best_collision_normal
		else:
			smoothed_friction_point = lerp(smoothed_friction_point, best_collision_point, 20.0 * delta)
			smoothed_friction_normal = lerp(smoothed_friction_normal, best_collision_normal, 20.0 * delta).normalized()
	else:
		friction_buffer_timer -= delta
		if friction_buffer_timer <= 0:
			is_fricting_walls = false
		else:
			smoothed_friction_point += velocity * delta

	if is_fricting_walls:
		friction_pos = smoothed_friction_point
		var current_dir = velocity.slide(smoothed_friction_normal).normalized()
		GameEvents.wall_friction_updated.emit(smoothed_friction_point, smoothed_friction_normal, current_dir)
		get_hurt(damageFromWallFriction * delta)

	if is_fricting_walls and not was_fricting:
		var current_dir = velocity.slide(smoothed_friction_normal).normalized()
		GameEvents.wall_friction_started.emit(smoothed_friction_point, smoothed_friction_normal, current_dir)
	elif not is_fricting_walls and was_fricting:
		GameEvents.wall_friction_ended.emit()
		smoothed_friction_point = Vector2.ZERO
		smoothed_friction_normal = Vector2.ZERO

	if is_fricting_walls:
		update_friction_vfx_position()


func update_friction_vfx_position() -> void:
	var current_dir = velocity.slide(smoothed_friction_normal).normalized()
	if current_dir == Vector2.ZERO:
		current_dir = velocity.normalized()


func get_hurt(damage: float) -> void:
	health -= damage
	if health <= 0:
		GameEvents.player_died.emit()
		pass
	GameEvents.player_hurt.emit()


func _on_wall_friction_started(global_pos: Vector2, normal: Vector2, direction: Vector2) -> void:
	print("friction start")
	friction_stream_player.play()


func _on_oxygen_timer_timeout() -> void:
	oxygen -= 0.5
	GameEvents.player_oxygen_changed.emit()
	pass # Replace with function body.


func _on_player_picked_fuel() -> void:
	energy += 50
	GameEvents.player_energy_changed.emit()
	if energy > maxEnergy:
		energy = maxEnergy


func _on_wall_friction_ended() -> void:
	print("friction end")
	friction_stream_player.stop()

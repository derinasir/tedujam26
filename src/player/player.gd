extends CharacterBody2D

const FORCE: float = 100.0
const THRUSTER_FORCE: float = 400.0
const FRICTION: float = 2.0
const BRAKE_FORCE: float = 5.0
const VELOCITY_CAP: float = 400.0

var is_thruster_on: bool = false

@onready var pivot: Node2D = $Pivot


func _process(_delta: float) -> void:
	is_thruster_on = Input.is_action_pressed("thruster")


func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down",
	)

	if input_dir != Vector2.ZERO:
		var final_force = THRUSTER_FORCE if is_thruster_on else FORCE

		if velocity.length() > 0 and input_dir.dot(velocity.normalized()) < 0:
			velocity = velocity.move_toward(Vector2.ZERO, final_force * BRAKE_FORCE * delta)

		velocity += input_dir * final_force * delta

		if not is_thruster_on:
			velocity = velocity.limit_length(VELOCITY_CAP)

		pivot.rotation = lerp_angle(pivot.rotation, velocity.angle(), 0.5)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FORCE * FRICTION * delta)

	move_and_slide()

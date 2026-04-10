class_name FiniteStateMachine
extends RefCounted

#var previous_state: State
var current_state: State


func setup(initial_state: State, msg: Dictionary = { }) -> void:
	if not is_instance_valid(initial_state):
		assert(false, "Couldn't setup: Initial state empty")
		return

	current_state = initial_state

	current_state.enter(msg)


func transition_to(new_state: State, msg: Dictionary = { }) -> void:
	if !new_state:
		assert(false, "Couldn't transition: New state returned null")

	if new_state == current_state:
		push_warning("Transitioning to the same state")

	current_state.exit()

	#previous_state = current_state
	current_state = new_state

	current_state.enter(msg)


func process(delta: float) -> void:
	var new_state = current_state.process(delta)
	if new_state:
		transition_to(new_state)


func physics_process(delta: float) -> void:
	var new_state = current_state.physics_process(delta)
	if new_state:
		transition_to(new_state)


func input(event: InputEvent) -> void:
	var new_state = current_state.input(event)
	if new_state:
		transition_to(new_state)


func send_event(event_name: StringName, data: Dictionary = { }) -> void:
	if not current_state:
		assert(false, "Couldn't send event: Current state is null")

	var next_state = current_state.handle_event(event_name, data)
	if next_state:
		transition_to(next_state)

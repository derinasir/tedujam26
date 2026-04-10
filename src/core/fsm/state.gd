class_name State
extends RefCounted

var name: String


func _init() -> void:
	name = ""


@warning_ignore("unused_parameter")
func enter(msg: Dictionary = { }) -> void:
	pass


func exit() -> void:
	pass


@warning_ignore("unused_parameter")
func process(delta: float) -> State:
	return null


@warning_ignore("unused_parameter")
func physics_process(delta: float) -> State:
	return null


@warning_ignore("unused_parameter")
func input(event: InputEvent) -> State:
	return null


func handle_event(_event_name: StringName, _data: Dictionary) -> State:
	return null

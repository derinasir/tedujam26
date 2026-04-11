extends Node

@warning_ignore_start("unused_signal")
signal player_spawned(player: Node)
signal player_died
signal level_change_requested(level_path: String)
signal pause_requested(should_pause: bool)
signal sonar_detected(group_name: String, data: Dictionary)
signal wall_friction_started(global_pos: Vector2, normal: Vector2, direction: Vector2)
signal wall_friction_ended
signal request_draw_dot(positions: Array[Vector2])

extends Node

@warning_ignore_start("unused_signal")
signal player_spawned(player: Node)
signal player_died
signal level_change_requested(level_path: String)
signal pause_requested(should_pause: bool)

class_name GameSettings
extends Resource

@export_group("Audio")
@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var sfx_volume: float = 0.8
@export_range(0.0, 1.0) var music_volume: float = 0.8
@export_group("Video")
@export var fullscreen: bool = false
@export var vsync: bool = true
@export_group("Controls")
@export_range(0.05, 1.0) var mouse_sensitivity: float = 0.2

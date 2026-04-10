extends Node

const SAVE_PATH = "user://settings.tres"

var current: GameSettings


func _ready() -> void:
	_load_settings()
	ServiceLocator.register(&"SettingsManager", self)


func save_settings() -> void:
	ResourceSaver.save(current, SAVE_PATH)
	_apply_settings()


func _load_settings() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded_res = ResourceLoader.load(SAVE_PATH)

		if loaded_res is GameSettings:
			current = loaded_res as GameSettings
		else:
			push_warning("Settings file is corrupted or wrong type. Creating new.")

	if not current:
		current = GameSettings.new()

	_apply_settings()


func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(current.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), linear_to_db(current.sfx_volume))

	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if current.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

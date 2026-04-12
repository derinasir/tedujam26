extends ProgressBar

const CRITICAL_VALUE: float = 50.0

@export var critical_audio_stream: AudioStream

var MAXTIME: float
var time_left: float
var is_critical: bool = false


func _ready() -> void:
	GameEvents.oxygen_critical.connect(_on_oxygen_critical)

	max_value = 100.0
	value = max_value
	MAXTIME = max_value
	time_left = MAXTIME


func _process(delta: float) -> void:
	time_left -= delta
	value = time_left

	if time_left <= 0:
		time_left = 0
		set_process(false)
		GameEvents.oxygen_depleted.emit()

	if time_left < CRITICAL_VALUE and not is_critical:
		is_critical = true
		GameEvents.oxygen_critical.emit()


func _on_oxygen_critical() -> void:
	SFXManager.play_sfx(critical_audio_stream)

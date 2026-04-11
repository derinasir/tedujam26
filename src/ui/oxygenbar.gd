extends ProgressBar
var MAXTIME: float 
var time_left: float

func _ready() -> void:
	value = max_value
	MAXTIME = max_value
	time_left = MAXTIME
	value = time_left 

func _process(delta: float) -> void:
	time_left -= delta
	value = time_left 
	if time_left <= 0:
		time_left = 0
		GameEvents.oxygen_depleted.emit()

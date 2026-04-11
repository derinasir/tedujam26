extends ProgressBar
@export var player: Player

func _ready() -> void:
	value = max_value
	GameEvents.player_oxygen_changed.connect(_on_player_oxygen_changed)
	pass 


func _process(delta: float) -> void:
	pass

func _on_player_oxygen_changed() -> void:
	value = player.oxygen

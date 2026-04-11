extends ProgressBar 
@export var player: Player

func _ready() -> void:
	GameEvents.player_energy_changed.connect(_on_player_energy_changed)

func _on_player_energy_changed() -> void:
	value = lerp(value, player.energy, 0.1)

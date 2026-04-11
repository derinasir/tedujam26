extends ProgressBar 
@export var player: Player


func _ready() -> void:
	GameEvents.player_hurt.connect(_on_player_hurt)
	pass 

func _on_player_hurt() -> void:
	value = lerp(value, player.health, 0.1)
	pass 

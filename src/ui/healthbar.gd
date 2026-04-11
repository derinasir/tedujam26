extends ProgressBar 
@export var player: Player


func _ready() -> void:
	
	pass 


func _process(delta: float) -> void:
	pass


func _on_player_2_wall_friction_ended() -> void:
	pass 


func _on_player_2_wall_friction_started(global_pos: Vector2, normal: Vector2) -> void:
	player.get_hurt(10.0)
	value = lerp(value, player.health, 0.1)
	pass 

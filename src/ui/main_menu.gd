extends Control

const GAME_SCENE: PackedScene = preload("uid://r66wywihg2l2")

@onready var TutorialScreen: TextureRect = $TutorialScreen
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_tutorial_pressed() -> void:
	TutorialScreen.visible = true
	pass # Replace with function body.


func _on_tutorial_exit_button_pressed() -> void:
	TutorialScreen.visible = false
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(GAME_SCENE)
	pass # Replace with function body.

extends GPUParticles2D

@export var bubble_sound_stream: AudioStream


func _ready() -> void:
	SFXManager.play_sfx(bubble_sound_stream)

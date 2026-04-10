extends Node

const POOL_SIZE: int = 32
const SFX_BUS: StringName = &"SFX"

var _pool: Array[AudioStreamPlayer] = []
var _active_queue: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_setup_pool()
	ServiceLocator.register(&"SFXManager", self)


func play_sfx(
		stream: AudioStream,
		pitch_variation: float = 0.0,
		volume_db: float = 0.0,
) -> void:
	if not stream:
		return

	var player: AudioStreamPlayer

	if not _pool.is_empty():
		player = _pool.pop_back()
	else:
		player = _active_queue.pop_front()
		player.stop()

	_active_queue.append(player)

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation) if pitch_variation > 0 else 1.0
	player.play()


func _setup_pool() -> void:
	for i in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		player.bus = SFX_BUS
		player.finished.connect(_on_stream_finished.bind(player))
		_pool.append(player)


func _on_stream_finished(player: AudioStreamPlayer) -> void:
	if player in _active_queue:
		_active_queue.erase(player)

	if not player in _pool:
		_pool.append(player)

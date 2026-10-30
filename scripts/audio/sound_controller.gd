class_name SoundController
extends Node
## Manages a polyphonic pool of pause-safe AudioStreamPlayers and mute state.
## Decoupled from gameplay entities; driven exclusively by GameManager events.

signal mute_changed(is_muted: bool)

const PLAYER_POOL_SIZE: int = 4

var _library: SfxCueLibrary = SfxCueLibrary.new()
var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _is_muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_player_pool()


func play_cue(cue: SfxCueLibrary.Cue, volume_db: float = 0.0) -> bool:
	if _is_muted or _players.is_empty():
		return false

	var stream: AudioStreamWAV = _library.get_stream(cue)
	if stream == null:
		return false

	var player: AudioStreamPlayer = _acquire_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	return true


func set_muted(muted: bool) -> void:
	if _is_muted == muted:
		return

	_is_muted = muted
	if _is_muted:
		stop_all()
	mute_changed.emit(_is_muted)


func toggle_mute() -> bool:
	set_muted(not _is_muted)
	if not _is_muted:
		play_cue(SfxCueLibrary.Cue.UI_CLICK, -3.0)
	return _is_muted


func is_muted() -> bool:
	return _is_muted


func has_cue(cue: SfxCueLibrary.Cue) -> bool:
	return _library.has_cue(cue)


func stop_all() -> void:
	for player in _players:
		if player.playing:
			player.stop()


func _initialize_player_pool() -> void:
	for i in range(PLAYER_POOL_SIZE):
		var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
		audio_player.name = "SfxPlayer%d" % i
		audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(audio_player)
		_players.append(audio_player)


func _acquire_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player

	var stolen_player: AudioStreamPlayer = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	return stolen_player

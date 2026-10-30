extends Node
## Self-contained Phase 6 verification suite covering procedural 16-bit PCM
## synthesis, SfxCueLibrary caching, SoundController pooling/muting, and UI/key sync.
## Open tests/phase6_audio_tests.tscn and press F6 in Godot Editor to run.

const GAME_SCENE_PATH: String = "res://scenes/main/game.tscn"

var _passed_count: int = 0
var _failed_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=== [LITTLE BOT] Running Phase 6 Retro Audio & SFX Tests ===")

	_test_synthesizer_pcm_integrity()
	_test_cue_library_completeness()
	await _test_sound_controller_pooling_and_mute()
	await _test_game_manager_ui_and_key_mute_sync()

	get_tree().paused = false
	print(
		"=== Phase 6 Tests Complete: %d passed, %d failed ==="
		% [_passed_count, _failed_count]
	)


func _test_synthesizer_pcm_integrity() -> void:
	var sweep: AudioStreamWAV = RetroWaveSynthesizer.create_pitch_sweep(
		240.0,
		560.0,
		0.10,
		RetroWaveSynthesizer.Waveform.PULSE_25
	)
	_assert_true(
		sweep != null
		and sweep.format == AudioStreamWAV.FORMAT_16_BITS
		and sweep.mix_rate == RetroWaveSynthesizer.SAMPLE_RATE
		and not sweep.stereo
		and sweep.data.size() > 4000
		and (sweep.data.size() % 2) == 0,
		"RetroWaveSynthesizer generates valid 16-bit mono PCM AudioStreamWAV buffers"
	)

	var first_sample: int = sweep.data.decode_s16(0)
	_assert_true(
		first_sample == 0,
		"Envelope starts smoothly at zero amplitude to prevent speaker click/pop artifacts"
	)


func _test_cue_library_completeness() -> void:
	var library: SfxCueLibrary = SfxCueLibrary.new()
	var all_cues_ready: bool = (
		library.has_cue(SfxCueLibrary.Cue.JUMP)
		and library.has_cue(SfxCueLibrary.Cue.ORB_PICKUP)
		and library.has_cue(SfxCueLibrary.Cue.CRASH)
		and library.has_cue(SfxCueLibrary.Cue.VICTORY)
		and library.has_cue(SfxCueLibrary.Cue.UI_CLICK)
	)
	_assert_true(
		all_cues_ready,
		"SfxCueLibrary pre-synthesizes and caches all 5 retro cyberpunk sound cues"
	)


func _test_sound_controller_pooling_and_mute() -> void:
	var controller: SoundController = SoundController.new()
	add_child(controller)
	await _wait_process_frames(1)

	var mute_emissions: Array[int] = [0]
	controller.mute_changed.connect(func(_muted: bool) -> void: mute_emissions[0] += 1)

	# Exercise polyphonic pool beyond PLAYER_POOL_SIZE (4)
	var all_played: bool = true
	for _i in range(5):
		if not controller.play_cue(SfxCueLibrary.Cue.UI_CLICK, -12.0):
			all_played = false

	_assert_true(
		all_played,
		"SoundController handles rapid polyphonic playback and voice-stealing cleanly"
	)

	controller.set_muted(true)
	controller.set_muted(true)
	_assert_true(
		controller.is_muted()
		and mute_emissions[0] == 1
		and not controller.play_cue(SfxCueLibrary.Cue.JUMP),
		"Muting stops active streams, suppresses playback, and emits mute_changed once"
	)

	controller.toggle_mute()
	_assert_true(
		not controller.is_muted() and mute_emissions[0] == 2,
		"SoundController.toggle_mute() unmutes and notifies listeners"
	)

	controller.stop_all()
	remove_child(controller)
	controller.queue_free()
	await _wait_process_frames(1)


func _test_game_manager_ui_and_key_mute_sync() -> void:
	var sub_vp: SubViewport = SubViewport.new()
	sub_vp.size = Vector2i(480, 270)
	sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_vp.handle_input_locally = true
	add_child(sub_vp)

	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	sub_vp.add_child(game)
	await _wait_process_frames(2)

	var main_menu: MainMenu = game.get_node("UILayer/MainMenu") as MainMenu
	var hud: GameHUD = game.get_node("UILayer/GameHUD") as GameHUD
	var menu_mute_btn: Button = main_menu.get_node("MuteButton") as Button
	var hud_mute_btn: Button = hud.get_node("MuteButton") as Button
	var hud_pause_btn: Button = hud.get_node("PauseButton") as Button
	var hud_progress: Control = hud.get_node("ProgressContainer") as Control

	_assert_true(
		InputActions.validate_registered_actions()
		and menu_mute_btn.focus_mode == Control.FOCUS_NONE
		and hud_mute_btn.focus_mode == Control.FOCUS_NONE,
		"Mute InputMap action registered and MuteButtons isolated from Spacebar focus"
	)

	main_menu.mute_toggle_requested.emit()
	await _wait_process_frames(1)

	_assert_true(
		game.get_sound_controller().is_muted()
		and menu_mute_btn.text == "MUTE"
		and hud_mute_btn.text == "MUTE",
		"Toggling mute updates SoundController and synchronizes both MainMenu and GameHUD buttons"
	)

	game.start_game()
	await _wait_physics_frames(2)

	var mute_rect: Rect2 = hud_mute_btn.get_global_rect()
	var pause_rect: Rect2 = hud_pause_btn.get_global_rect()
	var progress_rect: Rect2 = hud_progress.get_global_rect()
	_assert_true(
		not mute_rect.intersects(pause_rect) and not mute_rect.intersects(progress_rect),
		"GameHUD MuteButton maintains clean non-overlapping bounds with ProgressBar and PauseButton"
	)

	var m_key: InputEventKey = InputEventKey.new()
	m_key.keycode = KEY_M
	m_key.physical_keycode = KEY_M
	m_key.pressed = true
	sub_vp.push_input(m_key)
	await _wait_process_frames(1)

	_assert_true(
		not game.get_sound_controller().is_muted() and hud_mute_btn.text == "SFX",
		"Keyboard 'M' shortcut toggles mute state via centralized InputMap"
	)

	game.get_sound_controller().stop_all()
	get_tree().paused = false
	remove_child(sub_vp)
	sub_vp.queue_free()
	await _wait_process_frames(1)


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().physics_frame


func _wait_process_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		_passed_count += 1
		print("  [PASS] %s" % description)
	else:
		_failed_count += 1
		push_error("  [FAIL] %s" % description)

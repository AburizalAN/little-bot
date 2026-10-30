extends Node
## Self-contained Phase 5 verification suite covering keyboard controls,
## touchscreen input & UI isolation, multi-aspect-ratio UI layout resilience,
## Android back-navigation, and Web/Android export project settings.
## Open tests/phase5_platform_tests.tscn and press F6 in Godot Editor to run.

const GAME_SCENE_PATH: String = "res://scenes/main/game.tscn"
const HUD_SCENE_PATH: String = "res://scenes/ui/game_hud.tscn"
const GAME_OVER_SCENE_PATH: String = "res://scenes/ui/game_over.tscn"

var _passed_count: int = 0
var _failed_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=== [LITTLE BOT] Running Phase 5 Input & Platform Preparation Tests ===")

	await _test_keyboard_controls()
	await _test_touchscreen_and_pointer_controls()
	await _test_aspect_ratio_ui_layouts()
	await _test_android_back_navigation()
	_test_web_and_android_export_settings()

	get_tree().paused = false
	print(
		"=== Phase 5 Tests Complete: %d passed, %d failed ==="
		% [_passed_count, _failed_count]
	)


func _test_keyboard_controls() -> void:
	var sub_vp: SubViewport = _create_test_viewport(Vector2i(480, 270))
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	sub_vp.add_child(game)
	game.start_game()
	await _wait_physics_frames(4)

	var player: Player = game.get_active_level().get_player()
	var input_comp: PlayerInputComponent = player.get_node("PlayerInputComponent") as PlayerInputComponent

	sub_vp.push_input(_make_key_event(KEY_SPACE, true))
	_assert_true(
		input_comp.consume_jump_request(),
		"Keyboard Spacebar press triggers jump request via centralized InputMap"
	)

	sub_vp.push_input(_make_key_event(KEY_UP, true))
	_assert_true(
		input_comp.consume_jump_request(),
		"Keyboard Up Arrow press triggers jump request via centralized InputMap"
	)

	sub_vp.push_input(_make_key_event(KEY_ESCAPE, true))
	await _wait_process_frames(1)
	_assert_true(
		game.get_current_state() == GameState.State.PAUSED and get_tree().paused,
		"Keyboard Escape pauses gameplay cleanly"
	)

	# Spacebar while paused must not queue a latent gameplay jump
	sub_vp.push_input(_make_key_event(KEY_P, true))
	await _wait_process_frames(1)
	_assert_true(
		game.get_current_state() == GameState.State.PLAYING
		and not get_tree().paused
		and not input_comp.consume_jump_request(),
		"Keyboard P resumes gameplay without leaking buffered jump inputs"
	)

	await _cleanup_viewport(sub_vp)


func _test_touchscreen_and_pointer_controls() -> void:
	var sub_vp: SubViewport = _create_test_viewport(Vector2i(480, 270))
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	sub_vp.add_child(game)
	game.start_game()
	await _wait_physics_frames(4)

	var player: Player = game.get_active_level().get_player()
	var input_comp: PlayerInputComponent = player.get_node("PlayerInputComponent") as PlayerInputComponent

	# Finger release (pressed = false) must never trigger jump
	var touch_release: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_release.index = 0
	touch_release.position = Vector2(240.0, 160.0)
	touch_release.pressed = false
	sub_vp.push_input(touch_release)

	_assert_true(
		not input_comp.consume_jump_request(),
		"Touchscreen finger release (pressed=false) does not trigger accidental jump"
	)

	# Tap on gameplay area (even over top-center HUD progress region!) passes through HUD to jump
	var touch_press: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_press.index = 0
	touch_press.position = Vector2(240.0, 14.0)
	touch_press.pressed = true
	sub_vp.push_input(touch_press)

	_assert_true(
		input_comp.consume_jump_request(),
		"Touchscreen tap on non-button gameplay/HUD area passes through to trigger jump"
	)

	# Simultaneous native touch + emulated mouse press on mobile latches only a single jump
	sub_vp.push_input(touch_press)
	var mouse_press: InputEventMouseButton = InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.position = Vector2(240.0, 150.0)
	mouse_press.pressed = true
	sub_vp.push_input(mouse_press)

	var first_consume: bool = input_comp.consume_jump_request()
	var second_consume: bool = input_comp.consume_jump_request()
	_assert_true(
		first_consume and not second_consume,
		"Simultaneous touch + emulated mouse click latches exactly one jump request"
	)

	await _cleanup_viewport(sub_vp)


func _test_aspect_ratio_ui_layouts() -> void:
	var aspect_sizes: Array[Vector2i] = [
		Vector2i(480, 270), # 16:9 standard landscape
		Vector2i(600, 270), # 20:9 ultrawide mobile phone
		Vector2i(480, 360), # 4:3 tablet
	]

	var sub_vp: SubViewport = _create_test_viewport(Vector2i(480, 270))
	var hud: GameHUD = (load(HUD_SCENE_PATH) as PackedScene).instantiate() as GameHUD
	var game_over: GameOverScreen = (load(GAME_OVER_SCENE_PATH) as PackedScene).instantiate() as GameOverScreen
	sub_vp.add_child(hud)
	sub_vp.add_child(game_over)

	var all_layouts_valid: bool = true
	for vp_size in aspect_sizes:
		sub_vp.size = vp_size
		await _wait_process_frames(2)

		var vp_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(vp_size))
		var score_rect: Rect2 = (hud.get_node("ScoreChip") as Control).get_global_rect()
		var progress_rect: Rect2 = (hud.get_node("ProgressContainer") as Control).get_global_rect()
		var pause_rect: Rect2 = (hud.get_node("PauseButton") as Control).get_global_rect()
		var modal_card_rect: Rect2 = (game_over.get_node("Card") as Control).get_global_rect()

		var inside_bounds: bool = (
			vp_rect.encloses(score_rect)
			and vp_rect.encloses(progress_rect)
			and vp_rect.encloses(pause_rect)
			and vp_rect.encloses(modal_card_rect)
		)
		var no_hud_overlap: bool = (
			not score_rect.intersects(progress_rect)
			and not progress_rect.intersects(pause_rect)
			and not score_rect.intersects(pause_rect)
		)
		var card_centered: bool = (
			absf(modal_card_rect.get_center().x - (float(vp_size.x) * 0.5)) <= 2.0
			and absf(modal_card_rect.get_center().y - (float(vp_size.y) * 0.5)) <= 2.0
		)

		if not (inside_bounds and no_hud_overlap and card_centered):
			all_layouts_valid = false

	_assert_true(
		all_layouts_valid,
		"HUD and modal cards stay centered, non-overlapping, and in-bounds across 16:9, 20:9, and 4:3"
	)

	await _cleanup_viewport(sub_vp)


func _test_android_back_navigation() -> void:
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	add_child(game)
	game.start_game()
	await _wait_physics_frames(2)

	game.handle_back_request()
	_assert_true(
		game.get_current_state() == GameState.State.PAUSED,
		"Android Back gesture during PLAYING pauses gameplay instead of abruptly quitting"
	)

	game.handle_back_request()
	_assert_true(
		game.get_current_state() == GameState.State.PLAYING,
		"Android Back gesture during PAUSED resumes gameplay"
	)

	game.get_active_level().get_player().die()
	await _wait_process_frames(1)
	game.handle_back_request()
	_assert_true(
		game.get_current_state() == GameState.State.MAIN_MENU,
		"Android Back gesture on GAME_OVER navigates cleanly to MAIN_MENU"
	)

	get_tree().paused = false
	remove_child(game)
	game.queue_free()
	await _wait_process_frames(1)


func _test_web_and_android_export_settings() -> void:
	var desktop_renderer: String = String(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	var mobile_renderer: String = String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"))
	var etc2_astc: bool = bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"))
	var tex_filter: int = int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"))
	var snap_tx: bool = bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"))
	var stretch_mode: String = String(ProjectSettings.get_setting("display/window/stretch/mode"))
	var stretch_aspect: String = String(ProjectSettings.get_setting("display/window/stretch/aspect"))
	var quit_on_back: bool = bool(ProjectSettings.get_setting("application/config/quit_on_go_back"))
	var icon_res: Resource = load("res://icon.svg")

	_assert_true(
		desktop_renderer == "gl_compatibility" and mobile_renderer == "gl_compatibility",
		"Compatibility renderer configured for both Web (WebGL2) and Android (GLES3)"
	)
	_assert_true(
		etc2_astc,
		"ETC2/ASTC VRAM compression enabled for Android and Mobile Web export readiness"
	)
	_assert_true(
		tex_filter == 0 and snap_tx and stretch_mode == "viewport" and stretch_aspect == "keep",
		"Pixel-art display pipeline (Nearest filter, 2D pixel snap, 480x270 viewport keep-aspect) active"
	)
	_assert_true(
		not quit_on_back and icon_res != null,
		"Custom Android back-navigation flag and project icon (res://icon.svg) configured"
	)


func _create_test_viewport(vp_size: Vector2i) -> SubViewport:
	var sub_vp: SubViewport = SubViewport.new()
	sub_vp.size = vp_size
	sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_vp.handle_input_locally = true
	sub_vp.gui_embed_subwindows = true
	add_child(sub_vp)
	return sub_vp


func _make_key_event(key_code: Key, is_pressed: bool) -> InputEventKey:
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = key_code
	ev.physical_keycode = key_code
	ev.pressed = is_pressed
	return ev


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().physics_frame


func _wait_process_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame


func _cleanup_viewport(sub_vp: SubViewport) -> void:
	get_tree().paused = false
	remove_child(sub_vp)
	sub_vp.queue_free()
	await _wait_process_frames(1)


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		_passed_count += 1
		print("  [PASS] %s" % description)
	else:
		_failed_count += 1
		push_error("  [FAIL] %s" % description)

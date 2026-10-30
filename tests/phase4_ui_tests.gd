extends Node
## Self-contained Phase 4 UI flows, input isolation, and parallax verification suite.
## Open tests/phase4_ui_tests.tscn and press F6 in Godot Editor to run.

const GAME_SCENE_PATH: String = "res://scenes/main/game.tscn"

var _passed_count: int = 0
var _failed_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=== [LITTLE BOT] Running Phase 4 UI & Visual Polish Tests ===")

	await _test_main_menu_boot_and_play_flow()
	await _test_hud_updates_and_pause_menu_flow()
	await _test_game_over_and_level_completed_menu_navigation()

	get_tree().paused = false
	print(
		"=== Phase 4 Tests Complete: %d passed, %d failed ==="
		% [_passed_count, _failed_count]
	)


func _test_main_menu_boot_and_play_flow() -> void:
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	add_child(game)
	await _wait_process_frames(2)

	var main_menu: MainMenu = game.get_node("UILayer/MainMenu") as MainMenu
	var hud: GameHUD = game.get_node("UILayer/GameHUD") as GameHUD
	var menu_parallax: CyberpunkParallaxBg = main_menu.get_node("CyberpunkParallaxBg") as CyberpunkParallaxBg

	_assert_true(
		game.get_current_state() == GameState.State.MAIN_MENU
		and main_menu.visible
		and menu_parallax.visible
		and not hud.visible
		and game.get_active_level() == null,
		"Game boots cleanly into MAIN_MENU with active showcase parallax and no background level"
	)

	main_menu.play_requested.emit()
	await _wait_physics_frames(4)

	var level_parallax: CyberpunkParallaxBg = game.get_active_level().get_node("CyberpunkParallaxBg") as CyberpunkParallaxBg
	_assert_true(
		game.get_current_state() == GameState.State.PLAYING
		and not main_menu.visible
		and not menu_parallax.visible
		and hud.visible
		and level_parallax != null
		and level_parallax.visible,
		"Clicking Play hides MainMenu/menu-parallax, activates GameHUD, and mounts Level01 parallax"
	)

	await _cleanup_game(game)


func _test_hud_updates_and_pause_menu_flow() -> void:
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	add_child(game)
	game.start_game()
	await _wait_physics_frames(6)

	var hud: GameHUD = game.get_node("UILayer/GameHUD") as GameHUD
	var pause_btn: Button = hud.get_node("PauseButton") as Button
	var pause_menu: PauseMenu = game.get_node("UILayer/PauseMenu") as PauseMenu
	var score_label: Label = hud.get_node("ScoreChip/ScoreLabel") as Label
	var progress_bar: ProgressBar = hud.get_node("ProgressContainer/ProgressBar") as ProgressBar

	_assert_true(
		hud.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and pause_btn.focus_mode == Control.FOCUS_NONE,
		"GameHUD passes gameplay touch taps through and prevents Spacebar focus-hijacking on PauseButton"
	)

	game.get_score_manager().add_points(20)
	await _wait_process_frames(2)

	_assert_true(
		score_label.text == "SCORE 020" and progress_bar.value > 0.0,
		"GameHUD reflects live score updates and level traversal progress"
	)

	hud.pause_requested.emit()
	await _wait_process_frames(2)

	_assert_true(
		game.get_current_state() == GameState.State.PAUSED
		and pause_menu.visible
		and get_tree().paused,
		"PauseButton opens PauseMenu and freezes WorldContainer"
	)

	pause_menu.resume_requested.emit()
	await _wait_process_frames(2)

	_assert_true(
		game.get_current_state() == GameState.State.PLAYING
		and not pause_menu.visible
		and not get_tree().paused,
		"PauseMenu Resume restores PLAYING state and unpauses gameplay"
	)

	await _cleanup_game(game)


func _test_game_over_and_level_completed_menu_navigation() -> void:
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	add_child(game)
	game.start_game()
	await _wait_physics_frames(2)

	var main_menu: MainMenu = game.get_node("UILayer/MainMenu") as MainMenu
	var game_over: GameOverScreen = game.get_node("UILayer/GameOver") as GameOverScreen
	var completed: LevelCompletedScreen = game.get_node("UILayer/LevelCompleted") as LevelCompletedScreen

	game.get_score_manager().add_points(30)
	game.get_active_level().get_player().die()
	await _wait_process_frames(2)

	var go_score: Label = game_over.get_node("Card/VBox/FinalScoreLabel") as Label
	_assert_true(
		game.get_current_state() == GameState.State.GAME_OVER
		and game_over.visible
		and go_score.text == "FINAL SCORE: 30",
		"GameOver screen appears on player death and displays final score"
	)

	game_over.main_menu_requested.emit()
	await _wait_process_frames(2)

	_assert_true(
		game.get_current_state() == GameState.State.MAIN_MENU
		and main_menu.visible
		and not game_over.visible
		and game.get_active_level() == null
		and not get_tree().paused,
		"GameOver Main Menu button unloads level, unpauses tree, and returns to MainMenu"
	)

	# Start again and reach FinishLine
	main_menu.play_requested.emit()
	await _wait_physics_frames(2)

	var player: Player = game.get_active_level().get_player()
	player.global_position = Vector2(5502.0, 224.0)
	await _wait_physics_frames(12)

	var orbs_label: Label = completed.get_node("Card/VBox/OrbsLabel") as Label
	_assert_true(
		game.get_current_state() == GameState.State.LEVEL_COMPLETED
		and completed.visible
		and orbs_label.text.ends_with("/ 25"),
		"LevelCompleted screen appears at FinishLine with final score and orb summary"
	)

	completed.play_again_requested.emit()
	await _wait_physics_frames(2)

	_assert_true(
		game.get_current_state() == GameState.State.PLAYING
		and not completed.visible
		and game.get_active_level().get_player().global_position.x < 90.0,
		"LevelCompleted Play Again button restarts Level 01 cleanly"
	)

	await _cleanup_game(game)


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().physics_frame


func _wait_process_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame


func _cleanup_game(game: GameManager) -> void:
	get_tree().paused = false
	remove_child(game)
	game.queue_free()
	await get_tree().process_frame


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		_passed_count += 1
		print("  [PASS] %s" % description)
	else:
		_failed_count += 1
		push_error("  [FAIL] %s" % description)

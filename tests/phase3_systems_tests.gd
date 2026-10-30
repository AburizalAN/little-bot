extends Node
## Self-contained Phase 3 gameplay systems & edge-case verification suite.
## Open tests/phase3_systems_tests.tscn and press F6 in Godot Editor to run.

const GAME_SCENE_PATH: String = "res://scenes/main/game.tscn"
const ORB_SCENE_PATH: String = "res://scenes/collectibles/energy_orb.tscn"

var _passed_count: int = 0
var _failed_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=== [LITTLE BOT] Running Phase 3 Gameplay Systems Tests ===")

	_test_score_manager_operations()
	await _test_orb_collection_and_midgame_restart()
	await _test_orb_before_death_and_gameover_restart()
	await _test_finish_line_completion_and_race_guard()

	get_tree().paused = false
	print(
		"=== Phase 3 Tests Complete: %d passed, %d failed ==="
		% [_passed_count, _failed_count]
	)


func _test_score_manager_operations() -> void:
	var manager: ScoreManager = ScoreManager.new()
	var emissions: Array[int] = [0]
	manager.score_changed.connect(func(_new_score: int) -> void: emissions[0] += 1)

	manager.add_points(10)
	manager.add_points(15)
	manager.add_points(0)
	manager.add_points(-20)

	_assert_true(
		manager.get_score() == 25 and manager.get_collectibles_count() == 2,
		"ScoreManager accumulates positive points and ignores non-positive values"
	)
	_assert_true(
		emissions[0] == 2,
		"ScoreManager emits score_changed only on valid point additions"
	)

	manager.reset()
	_assert_true(
		manager.get_score() == 0 and manager.get_collectibles_count() == 0 and emissions[0] == 3,
		"ScoreManager.reset() zeroes score/count and notifies listeners"
	)


func _test_orb_collection_and_midgame_restart() -> void:
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	add_child(game)
	game.start_game()
	await _wait_physics_frames(3)

	var level: GameLevel = game.get_active_level()
	var initial_orbs: int = level.get_remaining_orb_count()
	_assert_true(initial_orbs == 25, "Level 01 initializes with all 25 EnergyOrbs")

	var player: Player = level.get_player()
	player.global_position = Vector2(232.0, 224.0)
	await _wait_physics_frames(8)

	_assert_true(
		game.get_current_score() >= 10 and level.get_remaining_orb_count() < initial_orbs,
		"Touching an EnergyOrb increases score and removes the collected orb"
	)

	var state_changes: Array[int] = [0]
	game.state_changed.connect(
		func(_prev: GameState.State, _next: GameState.State) -> void:
			state_changes[0] += 1
	)

	game.restart_level()
	await _wait_physics_frames(2)

	var restarted_level: GameLevel = game.get_active_level()
	var drone: Node2D = restarted_level.get_node("Obstacles/MovingDrone01") as Node2D
	_assert_true(
		game.get_current_state() == GameState.State.PLAYING
		and game.get_current_score() == 0
		and restarted_level.get_remaining_orb_count() == 25
		and restarted_level.get_player().global_position.x < 90.0
		and drone != null
		and drone.position.y > 205.0
		and state_changes[0] == 0,
		"Mid-gameplay restart resets player, score, orbs, and obstacles without duplicate PLAYING state emission"
	)

	await _cleanup_game(game)


func _test_orb_before_death_and_gameover_restart() -> void:
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	add_child(game)
	game.start_game()
	await _wait_physics_frames(2)

	var level: GameLevel = game.get_active_level()
	var pre_death_orb: EnergyOrb = (load(ORB_SCENE_PATH) as PackedScene).instantiate() as EnergyOrb
	pre_death_orb.position = Vector2(408.0, 212.0)
	level.add_child(pre_death_orb)
	level.register_orb(pre_death_orb)

	var player: Player = level.get_player()
	player.global_position = Vector2(404.0, 224.0)
	await _wait_physics_frames(10)

	_assert_true(
		game.get_current_state() == GameState.State.GAME_OVER
		and game.get_current_score() == 10,
		"Edge case: Orb touched immediately before spike death awards points once before GAME_OVER locks state"
	)

	var score_at_death: int = game.get_current_score()
	var post_death_orb: EnergyOrb = (load(ORB_SCENE_PATH) as PackedScene).instantiate() as EnergyOrb
	post_death_orb.global_position = player.global_position
	level.add_child(post_death_orb)
	level.register_orb(post_death_orb)
	await _wait_physics_frames(4)

	_assert_true(
		game.get_current_score() == score_at_death,
		"Dead player and GAME_OVER state reject any post-death score changes"
	)

	game.restart_level()
	await _wait_physics_frames(3)

	_assert_true(
		game.get_current_state() == GameState.State.PLAYING
		and not get_tree().paused
		and game.get_current_score() == 0
		and game.get_active_level().get_player().is_alive(),
		"Restarting from GAME_OVER unpauses world, resets score, and spawns live player"
	)

	await _cleanup_game(game)


func _test_finish_line_completion_and_race_guard() -> void:
	var game: GameManager = (load(GAME_SCENE_PATH) as PackedScene).instantiate() as GameManager
	add_child(game)
	game.start_game()
	await _wait_physics_frames(2)

	var level: GameLevel = game.get_active_level()
	var player: Player = level.get_player()
	player.global_position = Vector2(5502.0, 224.0)

	await _wait_physics_frames(12)

	_assert_true(
		game.get_current_state() == GameState.State.LEVEL_COMPLETED
		and get_tree().paused
		and player.is_alive(),
		"Reaching FinishLine transitions to LEVEL_COMPLETED and freezes gameplay cleanly"
	)

	level.player_died.emit()
	_assert_true(
		game.get_current_state() == GameState.State.LEVEL_COMPLETED,
		"LEVEL_COMPLETED rejects subsequent GAME_OVER race transitions"
	)

	await _cleanup_game(game)


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().physics_frame


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

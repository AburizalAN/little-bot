extends Node
## Lightweight self-contained test suite for Phase 1 foundation logic.
## Run this scene directly in Godot Editor (F6) to execute assertions.

var _passed_count: int = 0
var _failed_count: int = 0


func _ready() -> void:
	print("=== [LITTLE BOT] Running Phase 1 Foundation Tests ===")
	_test_input_actions_registered()
	_test_game_state_valid_transitions()
	_test_game_state_blocks_duplicate_and_invalid_transitions()
	_test_level_progress_calculation()

	print(
		"=== Phase 1 Tests Complete: %d passed, %d failed ==="
		% [_passed_count, _failed_count]
	)


func _test_input_actions_registered() -> void:
	_assert_true(
		InputActions.validate_registered_actions(),
		"Required InputMap actions ('jump', 'pause') are registered"
	)


func _test_game_state_valid_transitions() -> void:
	var state: GameState = GameState.new(GameState.State.MAIN_MENU)
	var emission_count: Array[int] = [0]
	state.state_changed.connect(
		func(_prev: GameState.State, _next: GameState.State) -> void:
			emission_count[0] += 1
	)

	_assert_true(
		state.transition_to(GameState.State.PLAYING),
		"MAIN_MENU -> PLAYING succeeds"
	)
	_assert_true(
		state.transition_to(GameState.State.PAUSED),
		"PLAYING -> PAUSED succeeds"
	)
	_assert_true(
		state.transition_to(GameState.State.PLAYING),
		"PAUSED -> PLAYING succeeds"
	)
	_assert_true(
		state.transition_to(GameState.State.GAME_OVER),
		"PLAYING -> GAME_OVER succeeds"
	)
	_assert_true(
		emission_count[0] == 4,
		"state_changed emitted exactly once per valid transition"
	)


func _test_game_state_blocks_duplicate_and_invalid_transitions() -> void:
	var state: GameState = GameState.new(GameState.State.PLAYING)
	_assert_true(
		not state.transition_to(GameState.State.PLAYING),
		"Duplicate PLAYING -> PLAYING transition is rejected"
	)
	_assert_true(
		state.transition_to(GameState.State.GAME_OVER),
		"PLAYING -> GAME_OVER succeeds"
	)
	_assert_true(
		not state.transition_to(GameState.State.LEVEL_COMPLETED),
		"Race transition GAME_OVER -> LEVEL_COMPLETED is rejected"
	)


func _test_level_progress_calculation() -> void:
	var level_scene: PackedScene = load("res://scenes/levels/level_01.tscn") as PackedScene
	_assert_true(level_scene != null, "level_01.tscn loads as PackedScene")
	if level_scene == null:
		return

	var level: GameLevel = level_scene.instantiate() as GameLevel
	add_child(level)

	var spawn_x: float = level.get_spawn_position().x
	var finish_x: float = level.get_finish_position().x
	var midpoint_x: float = (spawn_x + finish_x) * 0.5

	_assert_true(
		is_zero_approx(level.calculate_progress(spawn_x - 50.0)),
		"Progress clamps to 0.0 before spawn point"
	)
	_assert_true(
		is_equal_approx(level.calculate_progress(midpoint_x), 0.5),
		"Progress equals 0.5 at level midpoint"
	)
	_assert_true(
		is_equal_approx(level.calculate_progress(finish_x + 50.0), 1.0),
		"Progress clamps to 1.0 past finish point"
	)

	remove_child(level)
	level.queue_free()


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		_passed_count += 1
		print("  [PASS] %s" % description)
	else:
		_failed_count += 1
		push_error("  [FAIL] %s" % description)

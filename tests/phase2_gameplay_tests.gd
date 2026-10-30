extends Node
## Self-contained Phase 2 physics & gameplay verification suite.
## Open tests/phase2_gameplay_tests.tscn and press F6 in Godot Editor to run.

const PLAYER_SCENE_PATH: String = "res://scenes/player/player.tscn"
const GROUND_SCENE_PATH: String = "res://scenes/levels/ground_segment.tscn"
const SPIKE_SCENE_PATH: String = "res://scenes/obstacles/spike.tscn"
const MOVING_OBSTACLE_SCENE_PATH: String = "res://scenes/obstacles/moving_obstacle.tscn"

var _passed_count: int = 0
var _failed_count: int = 0


func _ready() -> void:
	print("=== [LITTLE BOT] Running Phase 2 Core Gameplay Tests ===")
	await _test_autorun_and_ground_collision()
	await _test_jump_and_airborne_jump_prevention()
	await _test_moving_obstacle_patrol()
	await _test_spike_collision_kills_player_once()
	await _test_gap_fall_into_killzone_kills_player()

	print(
		"=== Phase 2 Tests Complete: %d passed, %d failed ==="
		% [_passed_count, _failed_count]
	)


func _test_autorun_and_ground_collision() -> void:
	var sandbox: Node2D = Node2D.new()
	add_child(sandbox)

	var ground: GroundSegment = (load(GROUND_SCENE_PATH) as PackedScene).instantiate() as GroundSegment
	ground.position = Vector2(0.0, 224.0)
	ground.segment_width = 500.0
	sandbox.add_child(ground)

	var player: Player = (load(PLAYER_SCENE_PATH) as PackedScene).instantiate() as Player
	player.position = Vector2(48.0, 224.0)
	sandbox.add_child(player)

	await _wait_physics_frames(6)

	_assert_true(
		player.position.x > 55.0,
		"Player automatically runs horizontally along the track"
	)
	_assert_true(
		is_equal_approx(player.velocity.x, 150.0),
		"Player maintains consistent horizontal running speed"
	)
	_assert_true(
		player.is_on_floor(),
		"Player detects and rests cleanly on GroundSegment floor"
	)

	await _cleanup_sandbox(sandbox)


func _test_jump_and_airborne_jump_prevention() -> void:
	var sandbox: Node2D = Node2D.new()
	add_child(sandbox)

	var ground: GroundSegment = (load(GROUND_SCENE_PATH) as PackedScene).instantiate() as GroundSegment
	ground.position = Vector2(0.0, 224.0)
	ground.segment_width = 600.0
	sandbox.add_child(ground)

	var player: Player = (load(PLAYER_SCENE_PATH) as PackedScene).instantiate() as Player
	player.position = Vector2(48.0, 224.0)
	sandbox.add_child(player)

	await _wait_physics_frames(4)

	var input_comp: PlayerInputComponent = player.get_node("PlayerInputComponent") as PlayerInputComponent
	var jump_count: Array[int] = [0]
	player.jumped.connect(func() -> void: jump_count[0] += 1)

	input_comp.request_jump()
	await _wait_physics_frames(2)

	_assert_true(
		jump_count[0] == 1 and not player.is_on_floor() and player.velocity.y < -150.0,
		"Grounded jump request launches player upward with fixed jump impulse"
	)

	var airborne_vel_y_before: float = player.velocity.y
	input_comp.request_jump()
	await _wait_physics_frames(2)

	_assert_true(
		jump_count[0] == 1 and player.velocity.y > airborne_vel_y_before,
		"Airborne jump request is ignored while gravity continues accelerating downward"
	)

	await _cleanup_sandbox(sandbox)


func _test_moving_obstacle_patrol() -> void:
	var sandbox: Node2D = Node2D.new()
	add_child(sandbox)

	var drone: MovingObstacle = (load(MOVING_OBSTACLE_SCENE_PATH) as PackedScene).instantiate() as MovingObstacle
	drone.position = Vector2(200.0, 200.0)
	drone.move_offset = Vector2(0.0, -40.0)
	drone.cycle_duration = 0.4
	sandbox.add_child(drone)

	await _wait_physics_frames(12)

	_assert_true(
		drone.position.y < 190.0,
		"MovingObstacle PatrolMovementComponent oscillates position smoothly"
	)

	await _cleanup_sandbox(sandbox)


func _test_spike_collision_kills_player_once() -> void:
	var sandbox: Node2D = Node2D.new()
	add_child(sandbox)

	var ground: GroundSegment = (load(GROUND_SCENE_PATH) as PackedScene).instantiate() as GroundSegment
	ground.position = Vector2(0.0, 224.0)
	ground.segment_width = 400.0
	sandbox.add_child(ground)

	var player: Player = (load(PLAYER_SCENE_PATH) as PackedScene).instantiate() as Player
	player.position = Vector2(100.0, 224.0)
	sandbox.add_child(player)

	var died_emissions: Array[int] = [0]
	player.died.connect(func() -> void: died_emissions[0] += 1)

	var spike: Node2D = (load(SPIKE_SCENE_PATH) as PackedScene).instantiate() as Node2D
	spike.position = Vector2(108.0, 224.0)
	sandbox.add_child(spike)

	await _wait_physics_frames(6)
	player.die()

	_assert_true(
		not player.is_alive() and is_zero_approx(player.velocity.x),
		"Spike collision kills player and halts horizontal movement"
	)
	_assert_true(
		died_emissions[0] == 1,
		"Player 'died' signal emits at most once even on redundant die() calls"
	)

	await _cleanup_sandbox(sandbox)


func _test_gap_fall_into_killzone_kills_player() -> void:
	var sandbox: Node2D = Node2D.new()
	add_child(sandbox)

	var kill_zone: HazardComponent = HazardComponent.new()
	kill_zone.position = Vector2(150.0, 270.0)
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(400.0, 24.0)
	shape_node.shape = rect
	kill_zone.add_child(shape_node)
	sandbox.add_child(kill_zone)

	var player: Player = (load(PLAYER_SCENE_PATH) as PackedScene).instantiate() as Player
	player.position = Vector2(100.0, 224.0)
	sandbox.add_child(player)

	await _wait_physics_frames(25)

	_assert_true(
		not player.is_alive(),
		"Falling through a ground gap into KillZone triggers instant player death"
	)

	await _cleanup_sandbox(sandbox)


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().physics_frame


func _cleanup_sandbox(sandbox: Node2D) -> void:
	remove_child(sandbox)
	sandbox.queue_free()
	await get_tree().process_frame


func _assert_true(condition: bool, description: String) -> void:
	if condition:
		_passed_count += 1
		print("  [PASS] %s" % description)
	else:
		_failed_count += 1
		push_error("  [FAIL] %s" % description)

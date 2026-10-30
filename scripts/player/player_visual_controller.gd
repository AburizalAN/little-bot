class_name PlayerVisualController
extends Node2D
## Controls Little Bot's procedural pixel-art animation states (running stride,
## airborne tuck/tilt, antenna pulse, and crash expression) independently of physics.

const RUN_CYCLE_SPEED: float = 18.0
const BEACON_PULSE_SPEED: float = 6.0
const FOOT_STRIDE_X: float = 1.8
const FOOT_LIFT_Y: float = 1.6
const BODY_BOB_Y: float = 1.0
const AIR_TUCK_FOOT_Y: float = -1.5

const EYE_ACTIVE_COLOR: Color = Color(0.0, 0.96, 1.0, 1.0)
const EYE_CRASH_COLOR: Color = Color(1.0, 0.2, 0.55, 1.0)
const BEACON_BASE_COLOR: Color = Color(1.0, 0.22, 0.68, 1.0)

@onready var _left_foot: Polygon2D = $LeftFoot
@onready var _right_foot: Polygon2D = $RightFoot
@onready var _body_root: Node2D = $BodyRoot
@onready var _left_eye: Polygon2D = $BodyRoot/LeftEye
@onready var _right_eye: Polygon2D = $BodyRoot/RightEye
@onready var _antenna_beacon: Polygon2D = $BodyRoot/AntennaBeacon

var _run_cycle_time: float = 0.0
var _beacon_time: float = 0.0
var _left_foot_base: Vector2 = Vector2.ZERO
var _right_foot_base: Vector2 = Vector2.ZERO
var _body_base_y: float = 0.0
var _left_eye_base_y: float = 0.0
var _right_eye_base_y: float = 0.0


func _ready() -> void:
	_left_foot_base = _left_foot.position
	_right_foot_base = _right_foot.position
	_body_base_y = _body_root.position.y
	_left_eye_base_y = _left_eye.position.y
	_right_eye_base_y = _right_eye.position.y


func update_visuals(is_grounded: bool, current_velocity: Vector2, is_alive: bool, delta: float) -> void:
	if not is_alive:
		_apply_crashed_pose()
		return

	_beacon_time += delta * BEACON_PULSE_SPEED
	var pulse_alpha: float = 0.75 + 0.25 * sin(_beacon_time)
	_antenna_beacon.color = Color(
		BEACON_BASE_COLOR.r,
		BEACON_BASE_COLOR.g,
		BEACON_BASE_COLOR.b,
		pulse_alpha
	)

	_left_eye.color = EYE_ACTIVE_COLOR
	_right_eye.color = EYE_ACTIVE_COLOR
	_left_eye.scale.y = 1.0
	_right_eye.scale.y = 1.0

	if is_grounded:
		_apply_running_pose(delta)
	else:
		_apply_airborne_pose(current_velocity)


func _apply_running_pose(delta: float) -> void:
	_run_cycle_time += delta * RUN_CYCLE_SPEED
	var wave: float = sin(_run_cycle_time)

	_left_foot.position = Vector2(
		_left_foot_base.x + wave * FOOT_STRIDE_X,
		_left_foot_base.y - maxf(0.0, wave) * FOOT_LIFT_Y
	)
	_right_foot.position = Vector2(
		_right_foot_base.x - wave * FOOT_STRIDE_X,
		_right_foot_base.y - maxf(0.0, -wave) * FOOT_LIFT_Y
	)

	_body_root.position.y = _body_base_y - absf(wave) * BODY_BOB_Y
	_body_root.rotation = 0.0
	_left_eye.position.y = _left_eye_base_y
	_right_eye.position.y = _right_eye_base_y


func _apply_airborne_pose(current_velocity: Vector2) -> void:
	_left_foot.position = Vector2(_left_foot_base.x - 0.8, _left_foot_base.y + AIR_TUCK_FOOT_Y)
	_right_foot.position = Vector2(_right_foot_base.x + 0.8, _right_foot_base.y + AIR_TUCK_FOOT_Y)

	_body_root.position.y = _body_base_y
	_body_root.rotation = clampf(current_velocity.y * 0.0004, -0.10, 0.12)

	var eye_shift_y: float = clampf(current_velocity.y * 0.003, -1.0, 1.0)
	_left_eye.position.y = _left_eye_base_y + eye_shift_y
	_right_eye.position.y = _right_eye_base_y + eye_shift_y


func _apply_crashed_pose() -> void:
	_left_foot.position = _left_foot_base
	_right_foot.position = _right_foot_base
	_body_root.position.y = _body_base_y + 1.0
	_body_root.rotation = 0.16

	_left_eye.color = EYE_CRASH_COLOR
	_right_eye.color = EYE_CRASH_COLOR
	_left_eye.scale.y = 0.45
	_right_eye.scale.y = 0.45
	_antenna_beacon.color = EYE_CRASH_COLOR

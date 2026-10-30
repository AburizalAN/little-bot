class_name PatrolMovementComponent
extends Node
## Oscillates a target Node2D smoothly between its starting local position and
## start + move_offset over cycle_duration seconds.

@export var move_offset: Vector2 = Vector2(0.0, -48.0)
@export_range(0.2, 20.0, 0.05) var cycle_duration: float = 1.6
@export_range(0.0, 1.0, 0.01) var phase_offset: float = 0.0

var _target: Node2D = null
var _origin_position: Vector2 = Vector2.ZERO
var _elapsed_time: float = 0.0
var _is_active: bool = true


func _ready() -> void:
	_target = get_parent() as Node2D
	if _target == null:
		push_error("PatrolMovementComponent parent must extend Node2D.")
		return

	_origin_position = _target.position
	_apply_position_for_time(0.0)


func _physics_process(delta: float) -> void:
	if not _is_active or _target == null:
		return

	_elapsed_time += delta
	_apply_position_for_time(_elapsed_time)


func configure(offset: Vector2, duration: float, initial_phase: float = 0.0) -> void:
	move_offset = offset
	cycle_duration = maxf(duration, 0.2)
	phase_offset = clampf(initial_phase, 0.0, 1.0)
	if _target != null:
		_apply_position_for_time(_elapsed_time)


func set_active(active: bool) -> void:
	_is_active = active


func reset_to_origin() -> void:
	_elapsed_time = 0.0
	if _target != null:
		_apply_position_for_time(0.0)


func _apply_position_for_time(time_seconds: float) -> void:
	if is_zero_approx(cycle_duration):
		return

	var cycle_angle: float = ((time_seconds / cycle_duration) + phase_offset) * TAU
	# Normalized 0.0 -> 1.0 -> 0.0 smooth cosine wave starting at 0.0 when phase_offset == 0.0
	var blend: float = 0.5 * (1.0 - cos(cycle_angle))
	_target.position = _origin_position + (move_offset * blend)

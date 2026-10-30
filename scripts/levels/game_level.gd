class_name GameLevel
extends Node2D
## Root controller for a playable level scene.
## Coordinates spawn alignment, collectibles, finish trigger, and player lifecycle.

signal player_jumped
signal player_died
signal orb_collected(points: int)
signal level_completed

@onready var _spawn_point: Marker2D = $SpawnPoint
@onready var _finish_point: Marker2D = $FinishPoint
@onready var _player: Player = get_node_or_null("Player") as Player
@onready var _finish_line: FinishLine = get_node_or_null("FinishLine") as FinishLine
@onready var _collectibles_root: Node = get_node_or_null("Collectibles")

var _has_ended: bool = false
var _total_orb_count: int = 0


func _ready() -> void:
	if _spawn_point == null or _finish_point == null:
		push_error("GameLevel requires both SpawnPoint and FinishPoint Marker2D nodes.")

	if _player != null:
		if _spawn_point != null:
			_player.global_position = _spawn_point.global_position
		_player.jumped.connect(_on_player_jumped)
		_player.died.connect(_on_player_died)

	if _finish_line != null:
		_finish_line.reached.connect(_on_finish_line_reached)

	_connect_existing_collectibles()


func get_player() -> Player:
	return _player


func get_total_orb_count() -> int:
	return _total_orb_count


func get_remaining_orb_count() -> int:
	if _collectibles_root == null:
		return 0

	var count: int = 0
	for child in _collectibles_root.get_children():
		var orb: EnergyOrb = child as EnergyOrb
		if orb != null and not orb.is_collected():
			count += 1
	return count


func register_orb(orb: EnergyOrb) -> void:
	if orb != null and not orb.collected.is_connected(_on_orb_collected):
		orb.collected.connect(_on_orb_collected)
		_total_orb_count += 1


func get_spawn_position() -> Vector2:
	if _spawn_point == null:
		return Vector2.ZERO
	return _spawn_point.global_position


func get_finish_position() -> Vector2:
	if _finish_line != null:
		return _finish_line.global_position
	if _finish_point == null:
		return Vector2.ZERO
	return _finish_point.global_position


func get_current_progress() -> float:
	if _player == null:
		return 0.0
	return calculate_progress(_player.global_position.x)


func calculate_progress(current_x: float) -> float:
	if _spawn_point == null:
		return 0.0

	var finish_x: float = get_finish_position().x
	var start_x: float = _spawn_point.global_position.x
	var total_distance: float = finish_x - start_x
	if is_zero_approx(total_distance) or total_distance < 0.0:
		return 0.0

	return clampf((current_x - start_x) / total_distance, 0.0, 1.0)


func _connect_existing_collectibles() -> void:
	if _collectibles_root == null:
		return

	for child in _collectibles_root.get_children():
		var orb: EnergyOrb = child as EnergyOrb
		if orb != null:
			register_orb(orb)


func _on_player_jumped() -> void:
	if _has_ended:
		return
	player_jumped.emit()


func _on_orb_collected(points: int) -> void:
	if _has_ended:
		return
	orb_collected.emit(points)


func _on_player_died() -> void:
	if _has_ended:
		return
	_has_ended = true
	player_died.emit()


func _on_finish_line_reached() -> void:
	if _has_ended:
		return
	_has_ended = true
	if _player != null:
		_player.set_movement_enabled(false)
	level_completed.emit()

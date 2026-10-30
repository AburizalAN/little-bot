class_name ScoreManager
extends RefCounted
## Encapsulates score state, collectible count, and change notifications.

signal score_changed(new_score: int)

var _score: int = 0
var _collectibles_count: int = 0


func get_score() -> int:
	return _score


func get_collectibles_count() -> int:
	return _collectibles_count


func add_points(points: int) -> void:
	if points <= 0:
		return

	_score += points
	_collectibles_count += 1
	score_changed.emit(_score)


func reset() -> void:
	_score = 0
	_collectibles_count = 0
	score_changed.emit(_score)

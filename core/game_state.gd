class_name GameState
extends RefCounted
## Manages high-level game flow states and enforces valid state transitions.

signal state_changed(previous_state: State, new_state: State)

enum State {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	LEVEL_COMPLETED,
}

var _current_state: State = State.MAIN_MENU


func _init(initial_state: State = State.MAIN_MENU) -> void:
	_current_state = initial_state


func get_current_state() -> State:
	return _current_state


func is_playing() -> bool:
	return _current_state == State.PLAYING


func is_paused() -> bool:
	return _current_state == State.PAUSED


func can_transition_to(next_state: State) -> bool:
	if next_state == _current_state:
		return false

	match _current_state:
		State.MAIN_MENU:
			return next_state == State.PLAYING
		State.PLAYING:
			return (
				next_state == State.PAUSED
				or next_state == State.GAME_OVER
				or next_state == State.LEVEL_COMPLETED
				or next_state == State.MAIN_MENU
			)
		State.PAUSED:
			return (
				next_state == State.PLAYING
				or next_state == State.MAIN_MENU
			)
		State.GAME_OVER:
			return (
				next_state == State.PLAYING
				or next_state == State.MAIN_MENU
			)
		State.LEVEL_COMPLETED:
			return (
				next_state == State.PLAYING
				or next_state == State.MAIN_MENU
			)

	return false


func transition_to(next_state: State) -> bool:
	if not can_transition_to(next_state):
		return false

	var previous_state: State = _current_state
	_current_state = next_state
	state_changed.emit(previous_state, _current_state)
	return true


static func state_to_string(state: State) -> String:
	match state:
		State.MAIN_MENU:
			return "MAIN_MENU"
		State.PLAYING:
			return "PLAYING"
		State.PAUSED:
			return "PAUSED"
		State.GAME_OVER:
			return "GAME_OVER"
		State.LEVEL_COMPLETED:
			return "LEVEL_COMPLETED"
	return "UNKNOWN"

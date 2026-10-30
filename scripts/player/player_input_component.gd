class_name PlayerInputComponent
extends Node
## Translates centralized Input Map jump presses and unhandled gameplay screen
## taps into a single per-physics-frame jump request without interfering with UI controls.

var _is_enabled: bool = true
var _has_pending_jump: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if not _is_enabled:
		return

	if _is_jump_trigger_event(event):
		_has_pending_jump = true
		get_viewport().set_input_as_handled()


func set_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	if not _is_enabled:
		_has_pending_jump = false


func request_jump() -> void:
	if _is_enabled:
		_has_pending_jump = true


func consume_jump_request() -> bool:
	var requested: bool = _has_pending_jump
	_has_pending_jump = false
	return requested


func _is_jump_trigger_event(event: InputEvent) -> bool:
	if event.is_action_pressed(InputActions.JUMP):
		return true

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		return touch_event.pressed

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed

	return false

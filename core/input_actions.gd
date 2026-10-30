class_name InputActions
extends RefCounted
## Centralized registry of Input Map action names and startup verification.
## Prevents magic action strings across player and UI controllers.

const JUMP: StringName = &"jump"
const PAUSE: StringName = &"pause"
const MUTE: StringName = &"mute"


static func get_required_actions() -> Array[StringName]:
	return [
		JUMP,
		PAUSE,
		MUTE,
	]


static func validate_registered_actions() -> bool:
	var all_valid: bool = true
	for action in get_required_actions():
		if not InputMap.has_action(action):
			push_error("Missing required InputMap action: '%s'" % String(action))
			all_valid = false
	return all_valid

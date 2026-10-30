class_name Player
extends CharacterBody2D
## Playable Little Bot character composed of input, runner movement, hurtbox,
## and visual controller components.

signal jumped
signal died

const WORLD_PHYSICS_LAYER_MASK: int = 1
const PLAYER_PHYSICS_LAYER_MASK: int = 2

@onready var _input_component: PlayerInputComponent = $PlayerInputComponent
@onready var _movement_component: RunnerMovementComponent = $RunnerMovementComponent
@onready var _hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var _visual_controller: PlayerVisualController = $Visuals

var _is_alive: bool = true
var _is_movement_enabled: bool = true


func _ready() -> void:
	collision_layer = PLAYER_PHYSICS_LAYER_MASK
	collision_mask = WORLD_PHYSICS_LAYER_MASK
	_hurtbox_component.hazard_hit.connect(_on_hazard_hit)


func _physics_process(delta: float) -> void:
	if not _is_alive or not _is_movement_enabled:
		_visual_controller.update_visuals(is_on_floor(), velocity, _is_alive, delta)
		return

	var jump_requested: bool = _input_component.consume_jump_request()
	var did_jump: bool = _movement_component.step_movement(self, jump_requested, delta)
	if did_jump:
		jumped.emit()

	_visual_controller.update_visuals(is_on_floor(), velocity, _is_alive, delta)


func is_alive() -> bool:
	return _is_alive


func set_movement_enabled(enabled: bool) -> void:
	_is_movement_enabled = enabled
	_input_component.set_enabled(enabled and _is_alive)
	if not enabled:
		_movement_component.stop(self)


func die() -> void:
	if not _is_alive:
		return

	_is_alive = false
	_is_movement_enabled = false
	_input_component.set_enabled(false)
	_hurtbox_component.set_active(false)
	_movement_component.stop(self)
	_visual_controller.update_visuals(is_on_floor(), Vector2.ZERO, false, 0.0)
	died.emit()


func _on_hazard_hit(_hazard: HazardComponent) -> void:
	die()

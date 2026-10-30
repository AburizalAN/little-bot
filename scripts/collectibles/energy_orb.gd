class_name EnergyOrb
extends Area2D
## Collectible energy orb with lightweight procedural glow animation and
## one-shot collection safety.

signal collected(points: int)

const COLLECTIBLES_PHYSICS_LAYER_MASK: int = 8
const PLAYER_PHYSICS_LAYER_MASK: int = 2
const BOB_SPEED: float = 4.2
const BOB_AMPLITUDE_Y: float = 2.0
const PULSE_SPEED: float = 6.5

@export_range(1, 1000, 1) var point_value: int = 10

@onready var _visual_root: Node2D = $VisualRoot
@onready var _outer_aura: Polygon2D = $VisualRoot/OuterAura

var _is_collected: bool = false
var _anim_time: float = 0.0
var _phase_seed: float = 0.0


func _ready() -> void:
	collision_layer = COLLECTIBLES_PHYSICS_LAYER_MASK
	collision_mask = PLAYER_PHYSICS_LAYER_MASK
	monitoring = true
	monitorable = false

	_phase_seed = global_position.x * 0.025
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _is_collected:
		return

	_anim_time += delta
	var bob_angle: float = (_anim_time * BOB_SPEED) + _phase_seed
	_visual_root.position.y = sin(bob_angle) * BOB_AMPLITUDE_Y

	var pulse: float = 0.5 + 0.5 * sin((_anim_time * PULSE_SPEED) + _phase_seed)
	var aura_scale: float = lerpf(0.88, 1.18, pulse)
	_outer_aura.scale = Vector2(aura_scale, aura_scale)
	_outer_aura.color.a = lerpf(0.24, 0.52, pulse)


func is_collected() -> bool:
	return _is_collected


func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return

	var player: Player = body as Player
	if player == null or not player.is_alive():
		return

	_is_collected = true
	visible = false
	set_deferred("monitoring", false)
	collected.emit(point_value)
	queue_free()

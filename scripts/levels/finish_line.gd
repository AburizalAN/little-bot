class_name FinishLine
extends Area2D
## Level completion portal trigger with glowing energy beam pulse and one-shot guard.

signal reached

const TRIGGERS_PHYSICS_LAYER_MASK: int = 16
const PLAYER_PHYSICS_LAYER_MASK: int = 2
const BEAM_PULSE_SPEED: float = 5.0

@onready var _energy_beam: Polygon2D = $EnergyBeam
@onready var _top_beacon: Polygon2D = $TopBeacon

var _is_triggered: bool = false
var _anim_time: float = 0.0


func _ready() -> void:
	collision_layer = TRIGGERS_PHYSICS_LAYER_MASK
	collision_mask = PLAYER_PHYSICS_LAYER_MASK
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_anim_time += delta * BEAM_PULSE_SPEED
	var pulse: float = 0.5 + 0.5 * sin(_anim_time)
	_energy_beam.color.a = lerpf(0.22, 0.48, pulse)
	_top_beacon.color.a = lerpf(0.7, 1.0, pulse)


func is_triggered() -> bool:
	return _is_triggered


func _on_body_entered(body: Node2D) -> void:
	if _is_triggered:
		return

	var player: Player = body as Player
	if player == null or not player.is_alive():
		return

	_is_triggered = true
	set_deferred("monitoring", false)
	reached.emit()

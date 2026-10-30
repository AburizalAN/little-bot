class_name HurtboxComponent
extends Area2D
## Detects lethal HazardComponent overlaps for an entity and emits hazard_hit once.

signal hazard_hit(hazard: HazardComponent)

const HAZARDS_PHYSICS_LAYER_MASK: int = 4

var _is_active: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = HAZARDS_PHYSICS_LAYER_MASK
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)


func set_active(active: bool) -> void:
	_is_active = active
	set_deferred("monitoring", active)


func is_active() -> bool:
	return _is_active


func _on_area_entered(area: Area2D) -> void:
	if not _is_active:
		return

	var hazard: HazardComponent = area as HazardComponent
	if hazard == null:
		return

	set_active(false)
	hazard_hit.emit(hazard)

class_name HazardComponent
extends Area2D
## Marks an obstacle or kill-zone area as lethal on the 'hazards' physics layer.
## Passive (monitoring disabled) so only the player's HurtboxComponent performs checks.

const HAZARDS_PHYSICS_LAYER_MASK: int = 4

@export var hazard_type: StringName = &"spike"


func _ready() -> void:
	collision_layer = HAZARDS_PHYSICS_LAYER_MASK
	collision_mask = 0
	monitoring = false
	monitorable = true

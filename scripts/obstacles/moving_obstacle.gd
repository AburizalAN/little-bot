class_name MovingObstacle
extends Node2D
## Configurable moving hazard facade that forwards root Inspector settings
## to its composed PatrolMovementComponent.

@export var move_offset: Vector2 = Vector2(0.0, -48.0)
@export_range(0.2, 20.0, 0.05) var cycle_duration: float = 1.6
@export_range(0.0, 1.0, 0.01) var phase_offset: float = 0.0

@onready var _patrol_movement: PatrolMovementComponent = $PatrolMovementComponent


func _ready() -> void:
	_patrol_movement.configure(move_offset, cycle_duration, phase_offset)

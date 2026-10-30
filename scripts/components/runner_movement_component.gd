class_name RunnerMovementComponent
extends Node
## Handles horizontal auto-run velocity, gravity, and grounded fixed-impulse jumping
## for a CharacterBody2D without coupling to input devices, visuals, or game state.

@export_range(20.0, 600.0, 1.0) var run_speed: float = 150.0
@export_range(-800.0, -50.0, 1.0) var jump_velocity: float = -295.0
@export_range(100.0, 3000.0, 10.0) var gravity: float = 980.0
@export_range(100.0, 1500.0, 10.0) var max_fall_speed: float = 520.0


func step_movement(body: CharacterBody2D, jump_requested: bool, delta: float) -> bool:
	var next_velocity: Vector2 = body.velocity
	next_velocity.x = run_speed

	var did_jump: bool = false
	if body.is_on_floor():
		if jump_requested:
			next_velocity.y = jump_velocity
			did_jump = true
		elif next_velocity.y > 0.0:
			next_velocity.y = 0.0
	else:
		next_velocity.y = minf(next_velocity.y + gravity * delta, max_fall_speed)

	body.velocity = next_velocity
	body.move_and_slide()
	return did_jump


func stop(body: CharacterBody2D) -> void:
	body.velocity = Vector2.ZERO

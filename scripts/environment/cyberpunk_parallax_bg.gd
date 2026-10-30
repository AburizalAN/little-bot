class_name CyberpunkParallaxBg
extends ParallaxBackground
## Multi-layer pixel-art cyberpunk parallax background with lightweight star
## twinkling and optional auto-scroll for the Main Menu.

const STAR_TWINKLE_SPEED: float = 2.4

@export_range(0.0, 300.0, 1.0) var auto_scroll_speed: float = 0.0

@onready var _star_group_a: Node2D = $StarsLayer/StarGroupA
@onready var _star_group_b: Node2D = $StarsLayer/StarGroupB

var _twinkle_time: float = 0.0


func _process(delta: float) -> void:
	if not visible:
		return

	if auto_scroll_speed > 0.0:
		scroll_base_offset.x -= auto_scroll_speed * delta

	_twinkle_time += delta * STAR_TWINKLE_SPEED
	_star_group_a.modulate.a = 0.65 + 0.35 * sin(_twinkle_time)
	_star_group_b.modulate.a = 0.60 + 0.40 * cos(_twinkle_time * 1.3)


func set_active(active: bool) -> void:
	visible = active
	set_process(active)

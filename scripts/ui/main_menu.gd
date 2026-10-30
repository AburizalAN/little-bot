class_name MainMenu
extends Control
## Main Menu screen displaying title, tagline, scrolling cyberpunk parallax,
## animated Little Bot showcase character, Mute button, and Play action button.

signal play_requested
signal mute_toggle_requested

const SHOWCASE_HOP_INTERVAL: float = 2.6
const SHOWCASE_HOP_DURATION: float = 0.45
const SHOWCASE_HOP_HEIGHT: float = 16.0

@onready var _parallax_bg: CyberpunkParallaxBg = $CyberpunkParallaxBg
@onready var _stage_root: Node2D = $StageRoot
@onready var _bot_visuals: PlayerVisualController = $StageRoot/ShowcaseBot
@onready var _title_label: Label = $CenterCard/VBox/TitleLabel
@onready var _play_button: Button = $CenterCard/VBox/PlayButton
@onready var _mute_button: Button = $MuteButton

var _showcase_timer: float = 0.0
var _bot_base_y: float = 0.0


func _ready() -> void:
	_bot_base_y = _bot_visuals.position.y
	CyberUIStyle.style_button(_play_button, CyberUIStyle.NEON_CYAN, 13)
	_play_button.pressed.connect(_on_play_pressed)

	_mute_button.focus_mode = Control.FOCUS_NONE
	_mute_button.pressed.connect(_on_mute_pressed)
	update_mute_state(false)

	if _play_button.is_visible_in_tree():
		_play_button.grab_focus()


func _process(delta: float) -> void:
	if not visible:
		return

	_showcase_timer += delta
	var cycle_pos: float = fmod(_showcase_timer, SHOWCASE_HOP_INTERVAL)
	var is_hopping: bool = cycle_pos > (SHOWCASE_HOP_INTERVAL - SHOWCASE_HOP_DURATION)

	if is_hopping:
		var hop_progress: float = (
			(cycle_pos - (SHOWCASE_HOP_INTERVAL - SHOWCASE_HOP_DURATION))
			/ SHOWCASE_HOP_DURATION
		)
		var arc_y: float = -sin(hop_progress * PI) * SHOWCASE_HOP_HEIGHT
		var fake_vel_y: float = -cos(hop_progress * PI) * 220.0
		_bot_visuals.position.y = _bot_base_y + arc_y
		_bot_visuals.update_visuals(false, Vector2(150.0, fake_vel_y), true, delta)
	else:
		_bot_visuals.position.y = _bot_base_y
		_bot_visuals.update_visuals(true, Vector2(150.0, 0.0), true, delta)

	_title_label.modulate.a = 0.90 + 0.10 * sin(_showcase_timer * 3.2)


func set_menu_visible(should_show: bool) -> void:
	visible = should_show
	set_process(should_show)
	if _stage_root != null:
		_stage_root.visible = should_show
	if _parallax_bg != null:
		_parallax_bg.set_active(should_show)
	if should_show and _play_button != null and _play_button.is_visible_in_tree():
		_play_button.grab_focus()


func update_mute_state(is_muted: bool) -> void:
	if _mute_button == null:
		return
	_mute_button.text = "MUTE" if is_muted else "SFX"
	var accent: Color = CyberUIStyle.NEON_PINK if is_muted else CyberUIStyle.NEON_CYAN
	CyberUIStyle.style_button(_mute_button, accent, 9)


func _on_play_pressed() -> void:
	play_requested.emit()


func _on_mute_pressed() -> void:
	mute_toggle_requested.emit()

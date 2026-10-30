class_name GameHUD
extends Control
## In-game HUD displaying current score, level progress bar/percentage, and
## mobile-friendly Mute & Pause buttons without blocking gameplay touch input.

signal pause_requested
signal mute_toggle_requested

@onready var _score_chip: PanelContainer = $ScoreChip
@onready var _score_label: Label = $ScoreChip/ScoreLabel
@onready var _progress_bar: ProgressBar = $ProgressContainer/ProgressBar
@onready var _progress_label: Label = $ProgressContainer/ProgressLabel
@onready var _mute_button: Button = $MuteButton
@onready var _pause_button: Button = $PauseButton


func _ready() -> void:
	CyberUIStyle.style_hud_chip(_score_chip, CyberUIStyle.NEON_CYAN)
	CyberUIStyle.style_progress_bar(_progress_bar, CyberUIStyle.NEON_CYAN)
	CyberUIStyle.style_button(_pause_button, CyberUIStyle.NEON_PURPLE, 10)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.pressed.connect(_on_pause_pressed)

	_mute_button.focus_mode = Control.FOCUS_NONE
	_mute_button.pressed.connect(_on_mute_pressed)
	update_mute_state(false)


func update_score(new_score: int) -> void:
	if _score_label != null:
		_score_label.text = "SCORE %03d" % new_score


func update_progress(progress_ratio: float) -> void:
	var clamped: float = clampf(progress_ratio, 0.0, 1.0)
	var pct: int = roundi(clamped * 100.0)
	if _progress_bar != null:
		_progress_bar.value = clamped * 100.0
	if _progress_label != null:
		_progress_label.text = "%d%%" % pct


func update_mute_state(is_muted: bool) -> void:
	if _mute_button == null:
		return
	_mute_button.text = "MUTE" if is_muted else "SFX"
	var accent: Color = CyberUIStyle.NEON_PINK if is_muted else CyberUIStyle.NEON_CYAN
	CyberUIStyle.style_button(_mute_button, accent, 9)


func _on_pause_pressed() -> void:
	pause_requested.emit()


func _on_mute_pressed() -> void:
	mute_toggle_requested.emit()

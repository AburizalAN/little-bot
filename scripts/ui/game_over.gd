class_name GameOverScreen
extends Control
## Modal Game Over screen displaying final score, progress reached, Restart,
## and Main Menu navigation.

signal restart_requested
signal main_menu_requested

@onready var _card: PanelContainer = $Card
@onready var _score_label: Label = $Card/VBox/FinalScoreLabel
@onready var _progress_label: Label = $Card/VBox/ProgressLabel
@onready var _restart_button: Button = $Card/VBox/RestartButton
@onready var _main_menu_button: Button = $Card/VBox/MainMenuButton


func _ready() -> void:
	CyberUIStyle.style_panel(_card, CyberUIStyle.NEON_PINK)
	CyberUIStyle.style_button(_restart_button, CyberUIStyle.NEON_CYAN)
	CyberUIStyle.style_button(_main_menu_button, CyberUIStyle.NEON_PINK)

	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())


func show_results(final_score: int, progress_ratio: float) -> void:
	_score_label.text = "FINAL SCORE: %d" % final_score
	_progress_label.text = "DISTANCE: %d%%" % roundi(clampf(progress_ratio, 0.0, 1.0) * 100.0)
	if not visible:
		visible = true
		CyberUIStyle.animate_card_pop_in(self, _card)
	if _restart_button != null and _restart_button.is_visible_in_tree():
		_restart_button.grab_focus()


func hide_screen() -> void:
	visible = false

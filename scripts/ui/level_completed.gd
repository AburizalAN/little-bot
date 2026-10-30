class_name LevelCompletedScreen
extends Control
## Modal Level Completed screen displaying final score, collected orbs count,
## Play Again, and Main Menu navigation.

signal play_again_requested
signal main_menu_requested

@onready var _card: PanelContainer = $Card
@onready var _score_label: Label = $Card/VBox/FinalScoreLabel
@onready var _orbs_label: Label = $Card/VBox/OrbsLabel
@onready var _play_again_button: Button = $Card/VBox/PlayAgainButton
@onready var _main_menu_button: Button = $Card/VBox/MainMenuButton


func _ready() -> void:
	CyberUIStyle.style_panel(_card, CyberUIStyle.NEON_CYAN)
	CyberUIStyle.style_button(_play_again_button, CyberUIStyle.NEON_CYAN)
	CyberUIStyle.style_button(_main_menu_button, CyberUIStyle.NEON_PURPLE)

	_play_again_button.pressed.connect(func() -> void: play_again_requested.emit())
	_main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())


func show_results(final_score: int, orbs_collected: int, total_orbs: int) -> void:
	_score_label.text = "FINAL SCORE: %d" % final_score
	_orbs_label.text = "ENERGY ORBS: %d / %d" % [orbs_collected, total_orbs]
	if not visible:
		visible = true
		CyberUIStyle.animate_card_pop_in(self, _card)
	if _play_again_button != null and _play_again_button.is_visible_in_tree():
		_play_again_button.grab_focus()


func hide_screen() -> void:
	visible = false

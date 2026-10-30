class_name PauseMenu
extends Control
## Modal Pause overlay providing Resume, Restart, and Main Menu actions.

signal resume_requested
signal restart_requested
signal main_menu_requested

@onready var _card: PanelContainer = $Card
@onready var _resume_button: Button = $Card/VBox/ResumeButton
@onready var _restart_button: Button = $Card/VBox/RestartButton
@onready var _main_menu_button: Button = $Card/VBox/MainMenuButton


func _ready() -> void:
	CyberUIStyle.style_panel(_card, CyberUIStyle.NEON_PURPLE)
	CyberUIStyle.style_button(_resume_button, CyberUIStyle.NEON_CYAN)
	CyberUIStyle.style_button(_restart_button, CyberUIStyle.NEON_PURPLE)
	CyberUIStyle.style_button(_main_menu_button, CyberUIStyle.NEON_PINK)

	_resume_button.pressed.connect(func() -> void: resume_requested.emit())
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())


func show_menu() -> void:
	if visible:
		return
	visible = true
	CyberUIStyle.animate_card_pop_in(self, _card)
	if _resume_button != null and _resume_button.is_visible_in_tree():
		_resume_button.grab_focus()


func hide_menu() -> void:
	visible = false

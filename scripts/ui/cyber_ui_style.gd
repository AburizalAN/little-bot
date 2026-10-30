class_name CyberUIStyle
extends RefCounted
## Centralized neon cyberpunk styling and pause-safe UI entrance animations.
## Eliminates duplicated StyleBoxFlat definitions across menu and HUD scenes.

const COLOR_PANEL_BG: Color = Color(0.045, 0.058, 0.135, 0.94)
const COLOR_HUD_CHIP_BG: Color = Color(0.035, 0.048, 0.115, 0.82)
const COLOR_BUTTON_BG: Color = Color(0.07, 0.10, 0.22, 0.96)
const COLOR_BUTTON_HOVER_BG: Color = Color(0.12, 0.18, 0.36, 1.0)
const COLOR_BUTTON_PRESSED_BG: Color = Color(0.04, 0.06, 0.14, 1.0)

const NEON_CYAN: Color = Color(0.0, 0.95, 1.0, 1.0)
const NEON_PINK: Color = Color(1.0, 0.20, 0.60, 1.0)
const NEON_PURPLE: Color = Color(0.65, 0.26, 1.0, 1.0)
const TEXT_LIGHT: Color = Color(0.92, 0.97, 1.0, 1.0)


static func style_panel(panel: PanelContainer, border_color: Color, bg_color: Color = COLOR_PANEL_BG) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(2)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", box)


static func style_hud_chip(panel: PanelContainer, border_color: Color = NEON_CYAN) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = COLOR_HUD_CHIP_BG
	box.border_color = border_color
	box.set_border_width_all(1)
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", box)


static func style_button(button: Button, accent_color: Color, font_size: int = 11) -> void:
	var normal_box: StyleBoxFlat = _make_button_box(COLOR_BUTTON_BG, accent_color, 1)
	var hover_box: StyleBoxFlat = _make_button_box(COLOR_BUTTON_HOVER_BG, accent_color, 2)
	var pressed_box: StyleBoxFlat = _make_button_box(COLOR_BUTTON_PRESSED_BG, accent_color, 2)

	button.add_theme_stylebox_override("normal", normal_box)
	button.add_theme_stylebox_override("hover", hover_box)
	button.add_theme_stylebox_override("pressed", pressed_box)
	button.add_theme_stylebox_override("focus", hover_box)

	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", accent_color)
	button.add_theme_color_override("font_pressed_color", accent_color)
	button.add_theme_font_size_override("font_size", font_size)


static func style_progress_bar(bar: ProgressBar, fill_color: Color = NEON_CYAN) -> void:
	var bg_box: StyleBoxFlat = StyleBoxFlat.new()
	bg_box.bg_color = COLOR_HUD_CHIP_BG
	bg_box.border_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.45)
	bg_box.set_border_width_all(1)

	var fill_box: StyleBoxFlat = StyleBoxFlat.new()
	fill_box.bg_color = fill_color

	bar.add_theme_stylebox_override("background", bg_box)
	bar.add_theme_stylebox_override("fill", fill_box)


static func animate_card_pop_in(owner_node: Node, card: Control) -> void:
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.92, 0.92)
	card.modulate.a = 0.0

	var tween: Tween = owner_node.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.14)


static func _make_button_box(bg: Color, border: Color, border_px: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_px)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box

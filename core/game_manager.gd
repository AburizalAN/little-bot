class_name GameManager
extends Node
## High-level game coordinator managing active level lifecycle, ScoreManager,
## GameState transitions, retro SFX routing, Android back-navigation, and UI screens.

signal state_changed(previous_state: GameState.State, new_state: GameState.State)
signal score_changed(new_score: int)
signal level_restarted

@export var initial_level_scene: PackedScene

@onready var _world_container: Node2D = $WorldContainer
@onready var _sound_controller: SoundController = get_node_or_null("SoundController") as SoundController
@onready var _main_menu: MainMenu = get_node_or_null("UILayer/MainMenu") as MainMenu
@onready var _game_hud: GameHUD = get_node_or_null("UILayer/GameHUD") as GameHUD
@onready var _pause_menu: PauseMenu = get_node_or_null("UILayer/PauseMenu") as PauseMenu
@onready var _game_over_screen: GameOverScreen = get_node_or_null("UILayer/GameOver") as GameOverScreen
@onready var _level_completed_screen: LevelCompletedScreen = get_node_or_null("UILayer/LevelCompleted") as LevelCompletedScreen

var _game_state: GameState = GameState.new(GameState.State.MAIN_MENU)
var _score_manager: ScoreManager = ScoreManager.new()
var _active_level: GameLevel = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	InputActions.validate_registered_actions()
	_game_state.state_changed.connect(_on_game_state_changed)
	_score_manager.score_changed.connect(_on_score_changed)
	if _sound_controller != null:
		_sound_controller.mute_changed.connect(_on_mute_changed)
	_connect_ui_signals()

	_sync_ui_for_state(_game_state.get_current_state())

	var viewport_size: Vector2i = Vector2i(get_viewport().get_visible_rect().size)
	print(
		"[LITTLE BOT] Ready | Viewport: %dx%d | Renderer: Compatibility | State: %s"
		% [
			viewport_size.x,
			viewport_size.y,
			GameState.state_to_string(_game_state.get_current_state()),
		]
	)


func _process(_delta: float) -> void:
	if _game_state.is_playing() and _active_level != null and _game_hud != null:
		_game_hud.update_progress(_active_level.get_current_progress())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_request()


func _exit_tree() -> void:
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.PAUSE):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputActions.MUTE):
		toggle_mute()
		get_viewport().set_input_as_handled()


func start_game() -> void:
	if initial_level_scene == null:
		push_error("GameManager.initial_level_scene is not assigned.")
		return

	_play_sfx(SfxCueLibrary.Cue.UI_CLICK, -3.0)
	get_tree().paused = false
	_score_manager.reset()
	_load_level(initial_level_scene)
	if not _game_state.transition_to(GameState.State.PLAYING):
		_sync_ui_for_state(_game_state.get_current_state())


func restart_level() -> void:
	if initial_level_scene == null:
		push_error("GameManager.initial_level_scene is not assigned.")
		return

	_play_sfx(SfxCueLibrary.Cue.UI_CLICK, -3.0)
	get_tree().paused = false
	_score_manager.reset()
	_load_level(initial_level_scene)

	if _game_state.get_current_state() != GameState.State.PLAYING:
		_game_state.transition_to(GameState.State.PLAYING)
	else:
		_sync_ui_for_state(GameState.State.PLAYING)

	level_restarted.emit()


func return_to_main_menu() -> void:
	_play_sfx(SfxCueLibrary.Cue.UI_CLICK, -3.0)
	get_tree().paused = false
	_clear_active_level()
	_score_manager.reset()
	if not _game_state.transition_to(GameState.State.MAIN_MENU):
		_sync_ui_for_state(_game_state.get_current_state())


func toggle_pause() -> void:
	if _game_state.is_playing():
		_play_sfx(SfxCueLibrary.Cue.UI_CLICK, -3.0)
		_game_state.transition_to(GameState.State.PAUSED)
	elif _game_state.is_paused():
		_play_sfx(SfxCueLibrary.Cue.UI_CLICK, -3.0)
		_game_state.transition_to(GameState.State.PLAYING)


func toggle_mute() -> bool:
	if _sound_controller == null:
		return false
	return _sound_controller.toggle_mute()


func handle_back_request() -> void:
	match _game_state.get_current_state():
		GameState.State.PLAYING, GameState.State.PAUSED:
			toggle_pause()
		GameState.State.GAME_OVER, GameState.State.LEVEL_COMPLETED:
			return_to_main_menu()
		GameState.State.MAIN_MENU:
			if OS.get_name() != "Web":
				get_tree().quit()


func get_current_state() -> GameState.State:
	return _game_state.get_current_state()


func get_current_score() -> int:
	return _score_manager.get_score()


func get_score_manager() -> ScoreManager:
	return _score_manager


func get_sound_controller() -> SoundController:
	return _sound_controller


func get_active_level() -> GameLevel:
	return _active_level


func _connect_ui_signals() -> void:
	if _main_menu != null:
		_main_menu.play_requested.connect(start_game)
		_main_menu.mute_toggle_requested.connect(toggle_mute)

	if _game_hud != null:
		_game_hud.pause_requested.connect(toggle_pause)
		_game_hud.mute_toggle_requested.connect(toggle_mute)

	if _pause_menu != null:
		_pause_menu.resume_requested.connect(toggle_pause)
		_pause_menu.restart_requested.connect(restart_level)
		_pause_menu.main_menu_requested.connect(return_to_main_menu)

	if _game_over_screen != null:
		_game_over_screen.restart_requested.connect(restart_level)
		_game_over_screen.main_menu_requested.connect(return_to_main_menu)

	if _level_completed_screen != null:
		_level_completed_screen.play_again_requested.connect(restart_level)
		_level_completed_screen.main_menu_requested.connect(return_to_main_menu)


func _load_level(level_scene: PackedScene) -> void:
	_clear_active_level()

	var instance: Node = level_scene.instantiate()
	var game_level: GameLevel = instance as GameLevel
	if game_level == null:
		instance.free()
		push_error("Instantiated level scene root must extend GameLevel.")
		return

	_active_level = game_level
	_active_level.player_jumped.connect(_on_level_player_jumped)
	_active_level.player_died.connect(_on_level_player_died)
	_active_level.orb_collected.connect(_on_level_orb_collected)
	_active_level.level_completed.connect(_on_level_completed)
	_world_container.add_child(_active_level)


func _clear_active_level() -> void:
	if _active_level != null and is_instance_valid(_active_level):
		if _active_level.player_jumped.is_connected(_on_level_player_jumped):
			_active_level.player_jumped.disconnect(_on_level_player_jumped)
		if _active_level.player_died.is_connected(_on_level_player_died):
			_active_level.player_died.disconnect(_on_level_player_died)
		if _active_level.orb_collected.is_connected(_on_level_orb_collected):
			_active_level.orb_collected.disconnect(_on_level_orb_collected)
		if _active_level.level_completed.is_connected(_on_level_completed):
			_active_level.level_completed.disconnect(_on_level_completed)
		_world_container.remove_child(_active_level)
		_active_level.queue_free()
	_active_level = null


func _on_level_player_jumped() -> void:
	if not _game_state.is_playing():
		return
	_play_sfx(SfxCueLibrary.Cue.JUMP)


func _on_level_orb_collected(points: int) -> void:
	if not _game_state.is_playing():
		return
	_score_manager.add_points(points)
	_play_sfx(SfxCueLibrary.Cue.ORB_PICKUP)


func _on_level_player_died() -> void:
	if not _game_state.transition_to(GameState.State.GAME_OVER):
		return

	_play_sfx(SfxCueLibrary.Cue.CRASH)
	var progress_pct: float = 0.0
	if _active_level != null:
		progress_pct = _active_level.get_current_progress() * 100.0
	print(
		"[LITTLE BOT] Game Over | Score: %d | Progress: %.1f%%"
		% [_score_manager.get_score(), progress_pct]
	)


func _on_level_completed() -> void:
	if not _game_state.transition_to(GameState.State.LEVEL_COMPLETED):
		return

	_play_sfx(SfxCueLibrary.Cue.VICTORY)
	print("[LITTLE BOT] Level Completed! | Final Score: %d" % _score_manager.get_score())


func _on_score_changed(new_score: int) -> void:
	if _game_hud != null:
		_game_hud.update_score(new_score)
	score_changed.emit(new_score)


func _on_mute_changed(is_muted: bool) -> void:
	if _main_menu != null:
		_main_menu.update_mute_state(is_muted)
	if _game_hud != null:
		_game_hud.update_mute_state(is_muted)


func _on_game_state_changed(previous_state: GameState.State, new_state: GameState.State) -> void:
	var freeze_world: bool = (
		new_state == GameState.State.PAUSED
		or new_state == GameState.State.GAME_OVER
		or new_state == GameState.State.LEVEL_COMPLETED
	)
	get_tree().paused = freeze_world
	_sync_ui_for_state(new_state)
	state_changed.emit(previous_state, new_state)


func _sync_ui_for_state(current_state: GameState.State) -> void:
	var current_progress: float = 0.0
	var total_orbs: int = 0
	if _active_level != null:
		current_progress = _active_level.get_current_progress()
		total_orbs = _active_level.get_total_orb_count()

	var muted: bool = _sound_controller != null and _sound_controller.is_muted()

	if _main_menu != null:
		_main_menu.set_menu_visible(current_state == GameState.State.MAIN_MENU)
		_main_menu.update_mute_state(muted)

	if _game_hud != null:
		var show_hud: bool = current_state != GameState.State.MAIN_MENU
		_game_hud.visible = show_hud
		_game_hud.update_mute_state(muted)
		if show_hud:
			_game_hud.update_score(_score_manager.get_score())
			_game_hud.update_progress(current_progress)

	if _pause_menu != null:
		if current_state == GameState.State.PAUSED:
			_pause_menu.show_menu()
		else:
			_pause_menu.hide_menu()

	if _game_over_screen != null:
		if current_state == GameState.State.GAME_OVER:
			_game_over_screen.show_results(_score_manager.get_score(), current_progress)
		else:
			_game_over_screen.hide_screen()

	if _level_completed_screen != null:
		if current_state == GameState.State.LEVEL_COMPLETED:
			_level_completed_screen.show_results(
				_score_manager.get_score(),
				_score_manager.get_collectibles_count(),
				total_orbs
			)
		else:
			_level_completed_screen.hide_screen()


func _play_sfx(cue: SfxCueLibrary.Cue, volume_db: float = 0.0) -> void:
	if _sound_controller != null:
		_sound_controller.play_cue(cue, volume_db)

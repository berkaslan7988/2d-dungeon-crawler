## PauseMenu — Esc pauses the run: resume, the Altar of Souls, settings, back
## to the title (asks first: the run is lost) or quit.
extends CanvasLayer

const K = preload("res://scenes/ui/ui_kit.gd")
const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"

var _root: Control
var _menu: VBoxContainer
var _confirm: Control
var _settings: SettingsPanel
var _altar: AltarPanel


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in get_children():
		c.queue_free()
	_build()
	hide()
	Settings.changed.connect(func() -> void:
		if not visible:
			return
		var reopen := _settings.visible
		for c in get_children():
			c.queue_free()
		_build()
		if reopen:
			_menu.visible = false
			_settings.open.call_deferred())


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(K.scrim(0.7))
	_menu = K.vbox(2)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_child(_menu)
	var t := K.title(tr("PAUSE_TITLE"), 38)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(t)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	_menu.add_child(gap)
	_add(tr("PAUSE_RESUME"), _resume)
	_add(tr("TITLE_ALTAR"), func() -> void:
		_menu.visible = false
		_altar.open())
	_add(tr("TITLE_SETTINGS"), func() -> void:
		_menu.visible = false
		_settings.open())
	_add(tr("PAUSE_MAIN_MENU"), _ask_main_menu)
	if not OS.has_feature("web"):
		_add(tr("TITLE_QUIT"), func() -> void: get_tree().quit())

	_confirm = CenterContainer.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.visible = false
	_root.add_child(_confirm)
	var panel := K.panel(12, K.BLOOD)
	panel.custom_minimum_size = Vector2(240, 0)
	_confirm.add_child(panel)
	var col := K.vbox(10)
	panel.add_child(col)
	var q := K.label(tr("PAUSE_CONFIRM"), 10, K.PARCH)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(q)
	var row := K.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var yes := K.button(tr("PAUSE_CONFIRM_YES"), 10)
	yes.pressed.connect(func() -> void:
		get_tree().paused = false
		GameManager.change_scene(MAIN_MENU_SCENE))
	var no := K.button(tr("PAUSE_CONFIRM_NO"), 10)
	no.pressed.connect(_back_to_menu)
	row.add_child(no)
	row.add_child(yes)
	col.add_child(row)
	_confirm.set_meta("no", no)

	_settings = SettingsPanel.new()
	_settings.closed.connect(_back_to_menu)
	_root.add_child(_settings)
	_altar = AltarPanel.new()
	_altar.closed.connect(_back_to_menu)
	_root.add_child(_altar)


func _add(text: String, action: Callable) -> void:
	var b := K.menu_button(text, 14)
	b.pressed.connect(action)
	_menu.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	## Another screen (boons, chest, dialogue) owns the pause.
	if get_tree().paused and not visible:
		return
	if visible:
		if _settings.visible or _altar.visible:
			return  # those panels close themselves
		if _confirm.visible:
			_back_to_menu()
		else:
			_resume()
	else:
		_open()
	get_viewport().set_input_as_handled()


func _open() -> void:
	show()
	_menu.visible = true
	_confirm.visible = false
	get_tree().paused = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.15)
	(_menu.get_child(2) as Button).grab_focus.call_deferred()


func _resume() -> void:
	hide()
	get_tree().paused = false


func _ask_main_menu() -> void:
	_menu.visible = false
	_confirm.visible = true
	(_confirm.get_meta("no") as Button).grab_focus()


func _back_to_menu() -> void:
	_confirm.visible = false
	_menu.visible = true
	(_menu.get_child(2) as Button).grab_focus.call_deferred()

## DeathScreen — the end of a run, death or victory: what you reached and
## the souls it earned. Listens to EventBus.run_ended.
extends CanvasLayer

const K = preload("res://scenes/ui/ui_kit.gd")

var _root: Control
var _title: Label
var _sub: Label
var _stats: GridContainer
var _retry: Button
var _menu: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in get_children():
		c.queue_free()
	_build()
	hide()
	EventBus.run_ended.connect(_on_run_ended)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(K.scrim(0.86))
	var col := K.vbox(8)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_child(col)
	_title = K.title("", 48)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_sub = K.label("", 11, K.BONE)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_sub)
	var center := CenterContainer.new()
	col.add_child(center)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 24)
	_stats.add_theme_constant_override("v_separation", 2)
	center.add_child(_stats)
	var buttons := K.hbox(8)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_retry = K.button("", 11)
	_retry.pressed.connect(_on_retry_pressed)
	_menu = K.button("", 11)
	_menu.pressed.connect(_on_menu_pressed)
	buttons.add_child(_retry)
	buttons.add_child(_menu)
	col.add_child(buttons)


func _on_run_ended(victory: bool) -> void:
	await get_tree().create_timer(0.8).timeout
	_populate(victory)
	_open()


func _populate(victory: bool) -> void:
	_title.text = tr("END_VICTORY") if victory else tr("END_DEATH")
	_title.add_theme_color_override("font_color", K.GOLD_LT if victory else K.PARCH)
	_title.add_theme_color_override("font_shadow_color", K.EMBER_DK if victory else K.BLOOD_DK)
	_sub.text = tr("END_VICTORY_SUB") if victory else tr("END_DEATH_SUB")
	for c in _stats.get_children():
		c.queue_free()
	var secs := int(RunManager.get_run_duration())
	@warning_ignore("integer_division")
	var time := "%d:%02d" % [secs / 60, secs % 60]
	_stat(tr("END_FLOOR"), str(RunManager.current_floor), K.PARCH)
	_stat(tr("END_SLAIN"), str(RunManager.enemies_killed), K.PARCH)
	_stat(tr("END_LEVEL"), str(RunManager.level), K.PARCH)
	_stat(tr("END_TIME"), time, K.PARCH)
	_stat(tr("END_SOULS"), "+%d" % GameManager.last_run_reward, K.GOLD)
	_retry.text = tr("END_RETRY")
	_menu.text = tr("END_MENU")


func _stat(label: String, value: String, color: Color) -> void:
	var l := K.num(label, 13, K.ASH_LT)
	_stats.add_child(l)
	var v := K.num(value, 13, color)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stats.add_child(v)


func _open() -> void:
	show()
	get_tree().paused = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.5)
	_retry.grab_focus.call_deferred()


func _on_retry_pressed() -> void:
	hide()
	get_tree().paused = false
	RunManager.start_run()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	hide()
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

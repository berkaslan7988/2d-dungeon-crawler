## ChestScreen — a chest opens when you walk up to it: the run pauses, its
## contents are listed (and a boon, sometimes), "Take all" puts everything in
## the inventory.
extends CanvasLayer

const K = preload("res://scenes/ui/ui_kit.gd")

var _items: Array = []
var _upgrade: UpgradeData = null
var _root: Control
var _list: VBoxContainer
var _title: Label
var _take: Button


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in get_children():
		c.queue_free()
	_build()
	hide()
	EventBus.chest_opened.connect(_on_chest_opened)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(K.scrim(0.6))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := K.panel(12, K.BRONZE)
	panel.custom_minimum_size = Vector2(230, 0)
	center.add_child(panel)
	var col := K.vbox(8)
	panel.add_child(col)
	_title = K.title("", 28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_list = K.vbox(4)
	col.add_child(_list)
	_take = K.button("", 10)
	_take.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_take.pressed.connect(_on_take)
	col.add_child(_take)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("inventory") or event.is_action_pressed("interact") \
			or event.is_action_pressed("ui_accept"):
		_on_take()
		get_viewport().set_input_as_handled()


func _on_chest_opened(items: Array, upgrade: UpgradeData) -> void:
	_items = items
	_upgrade = upgrade
	_title.text = tr("CHEST_TITLE")
	_take.text = tr("CHEST_TAKE")
	_fill()
	show()
	get_tree().paused = true
	_take.grab_focus.call_deferred()
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.18)


func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	var counts: Dictionary = {}
	var order: Array = []
	for it in _items:
		if not counts.has(it):
			counts[it] = 0
			order.append(it)
		counts[it] += 1
	if order.is_empty() and _upgrade == null:
		var empty := K.label(tr("CHEST_EMPTY"), 10, K.ASH_LT)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
	for it in order:
		var row := K.hbox(6)
		var slot := K.panel(1, K.SLATE_3, K.VOID)
		slot.add_child(K.icon(it.icon))
		row.add_child(slot)
		var name := K.label(it.get_name_text(), 10, K.item_color(it.rarity), K.font_medium())
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name)
		var n: int = counts[it]
		if n > 1:
			var c := K.num("×%d" % n, 13, K.BONE)
			c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(c)
		_list.add_child(row)
	if _upgrade != null:
		var sep := ColorRect.new()
		sep.color = K.SLATE_2
		sep.custom_minimum_size = Vector2(0, 1)
		_list.add_child(sep)
		var row := K.hbox(6)
		var plate := K.panel(1, K.boon_color(_upgrade.rarity), K.VOID)
		plate.add_child(K.icon(K.glyph_for(_upgrade)))
		row.add_child(plate)
		var t := K.vbox(0)
		t.add_child(K.num(tr("CHEST_BOON").to_upper(), 11, K.boon_color(_upgrade.rarity)))
		t.add_child(K.label("%s · %s" % [_upgrade.get_name_text(), _upgrade.get_desc_text()], 9, K.PARCH))
		row.add_child(t)
		_list.add_child(row)


func _on_take() -> void:
	if RunManager.inventory != null:
		for it in _items:
			RunManager.inventory.add_item(it, 1)
	if _upgrade != null:
		RunManager.confirm_upgrade(_upgrade)
	_items = []
	_upgrade = null
	hide()
	get_tree().paused = false

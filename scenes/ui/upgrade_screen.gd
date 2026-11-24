## UpgradeScreen — level up: the run pauses and three boons are offered.
## Cards are framed in their rarity's metal (iron, bronze, gold); 1/2/3,
## arrows + Enter or a click picks one.
extends CanvasLayer

const K = preload("res://scenes/ui/ui_kit.gd")
const CARD := Vector2(132, 172)

var _root: Control
var _title: Label
var _cards: HBoxContainer
var _carets: HBoxContainer
var _current_choices: Array[UpgradeData] = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in get_children():
		c.queue_free()
	_build()
	hide()
	EventBus.player_leveled_up.connect(_on_player_leveled_up)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(K.scrim(0.66))
	_title = K.title("", 40)
	_place(_title, 34)
	var sub := K.shadowed(K.label(tr("BOON_CHOOSE"), 11, K.BONE))
	sub.name = "Sub"
	_place(sub, 82)
	_carets = K.hbox(20)
	_carets.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(_carets, 104)
	_cards = K.hbox(20)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(_cards, 116)
	var hint := K.shadowed(K.num(tr("BOON_HINT"), 11, K.ASH_LT))
	hint.name = "Hint"
	_place(hint, 306)


func _place(c: Control, top: float) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	c.offset_top = top
	if c is Label:
		(c as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(c)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _current_choices.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := [KEY_1, KEY_2, KEY_3].find(event.keycode)
		if idx != -1 and idx < _current_choices.size():
			_on_card_selected(_current_choices[idx])
			get_viewport().set_input_as_handled()


func _on_player_leveled_up(new_level: int) -> void:
	_current_choices = RunManager.offer_upgrades()
	if _current_choices.is_empty():
		push_warning("UpgradeScreen: upgrade_pool boş, ekran açılmıyor.")
		return
	_title.text = tr("BOON_LEVEL") % new_level
	(_root.find_child("Sub", true, false) as Label).text = tr("BOON_CHOOSE")
	(_root.find_child("Hint", true, false) as Label).text = tr("BOON_HINT")
	_build_cards()
	_open()


func _build_cards() -> void:
	for c in _cards.get_children():
		c.queue_free()
	for c in _carets.get_children():
		c.queue_free()
	for i in _current_choices.size():
		var caret := K.icon(K.EMBER_ICON, 1)
		caret.custom_minimum_size = Vector2(CARD.x, 8)
		caret.modulate.a = 0.0
		_carets.add_child(caret)
		var card := _make_card(_current_choices[i], i, caret)
		_cards.add_child(card)
	(_cards.get_child(0) as Button).grab_focus.call_deferred()


func _make_card(u: UpgradeData, index: int, caret: Control) -> Button:
	var metal := K.boon_color(u.rarity)
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.focus_mode = Control.FOCUS_ALL
	var normal := K.frame(K.SOOT, metal, 2, 0)
	var hot := K.frame(K.SLATE_1, K.GOLD_LT, 2, 0)
	for st in ["normal", "disabled"]:
		b.add_theme_stylebox_override(st, normal)
	for st in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, hot)
	b.focus_entered.connect(func() -> void: caret.modulate.a = 1.0)
	b.focus_exited.connect(func() -> void: caret.modulate.a = 0.0)
	b.mouse_entered.connect(b.grab_focus)
	b.pressed.connect(_on_card_selected.bind(u))

	var v := K.vbox(6)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.offset_right = -10
	v.offset_top = 9
	v.offset_bottom = -9
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var rarity := K.num(K.boon_rarity_name(u.rarity).to_upper(), 12, metal)
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rarity)
	var plate := K.panel(8, K.SLATE_3, K.VOID)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.add_child(K.icon(K.glyph_for(u), 2))
	v.add_child(plate)
	var name := K.label(u.get_name_text(), 12, K.PARCH, K.font_medium())
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name)
	var desc := K.label(u.get_desc_text(), 10, K.BONE)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var key := K.key_cap(str(index + 1), index == 0)
	key.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(key)
	for n in v.find_children("*", "Control", true, false):
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _open() -> void:
	show()
	get_tree().paused = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.18)


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func() -> void:
		hide()
		_root.modulate.a = 1.0
		get_tree().paused = false)


func _on_card_selected(upgrade: UpgradeData) -> void:
	if _current_choices.is_empty():
		return
	_current_choices = []
	EventBus.sfx_requested.emit(&"ui_click")
	RunManager.confirm_upgrade(upgrade)
	_close()

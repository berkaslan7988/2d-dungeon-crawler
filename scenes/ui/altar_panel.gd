## AltarPanel — the meta shop. Souls earned across runs buy boons that are
## applied at the start of every run (GameManager.meta_shop_pool).
class_name AltarPanel
extends Control

signal closed

const K = preload("res://scenes/ui/ui_kit.gd")

var _first: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.meta_currency_changed.connect(func(_t: int) -> void:
		if visible:
			_build())


func open() -> void:
	_build()
	visible = true
	if _first != null:
		_first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		visible = false
		closed.emit()
		get_viewport().set_input_as_handled()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_first = null
	add_child(K.scrim(0.82))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := K.vbox(10)
	center.add_child(col)

	var head := K.title(tr("ALTAR_TITLE"), 34)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var sub := K.label(tr("ALTAR_SUBTITLE"), 10, K.BONE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var souls := K.hbox(4)
	souls.alignment = BoxContainer.ALIGNMENT_CENTER
	souls.add_child(K.icon(K.SOUL_ICON))
	souls.add_child(K.num(str(GameManager.meta_currency), 16, K.GOLD))
	souls.add_child(K.num(tr("COMMON_SOULS"), 11, K.ASH_LT))
	col.add_child(souls)

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(grid)
	if GameManager.meta_shop_pool != null:
		for u in GameManager.meta_shop_pool.upgrades:
			grid.add_child(_card(u))

	var back := K.button(tr("COMMON_BACK"), 10)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	col.add_child(back)
	if _first == null:
		_first = back


func _card(u: UpgradeData) -> PanelContainer:
	var owned := GameManager.is_meta_upgrade_purchased(u.id)
	var card := K.panel(8, K.GOLD if owned else K.SLATE_3, K.SOOT)
	card.custom_minimum_size = Vector2(104, 128)
	var v := K.vbox(5)
	card.add_child(v)
	var plate := K.panel(4, K.SLATE_2, K.VOID)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.add_child(K.icon(K.glyph_for(u), 2))
	v.add_child(plate)
	var name := K.label(u.get_name_text(), 10, K.PARCH, K.font_medium())
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name)
	var desc := K.label(u.get_desc_text(), 9, K.BONE)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var b := K.button(tr("ALTAR_OWNED") if owned else "%d %s" % [u.meta_cost, tr("COMMON_SOULS_SHORT")], 9)
	b.disabled = owned or GameManager.meta_currency < u.meta_cost
	b.pressed.connect(func() -> void: GameManager.purchase_meta_upgrade(u))
	v.add_child(b)
	if _first == null and not b.disabled:
		_first = b
	return card

## InventoryUI — E opens the pack: four equipment slots and the bag.
## Click a weapon or armour to wear it (the old piece goes back in the bag),
## click a potion to drink it, right-click to turn a spare item into souls.
## Data lives on RunManager (inventory/equipment survive floor changes);
## the UI redraws on inventory_changed / equipment_changed.
class_name InventoryUI
extends CanvasLayer

const K = preload("res://scenes/ui/ui_kit.gd")
const SLOT := Vector2(24, 24)
const COLUMNS: int = 8
const EQUIP_SLOT_NAMES: Array[String] = ["weapon", "head", "chest", "feet"]
const EQUIP_KEYS := {"weapon": "INV_WEAPON", "head": "INV_HEAD", "chest": "INV_CHEST", "feet": "INV_FEET"}

var _root: Control
var _panel: PanelContainer
var _equip_row: HBoxContainer
var _grid: GridContainer
var _tooltip: PanelContainer
var _tooltip_box: VBoxContainer


func _ready() -> void:
	layer = 12
	for c in get_children():
		c.queue_free()
	_build()
	_root.visible = false
	EventBus.run_started.connect(_on_run_started)
	if RunManager.inventory != null:
		_on_run_started()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_panel = K.panel(10)
	_panel.position = Vector2(150, 70)
	_root.add_child(_panel)
	var col := K.vbox(8)
	_panel.add_child(col)
	var head := K.hbox(8)
	var t := K.title(tr("INV_TITLE"), 24)
	t.name = "Title"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var hint := K.num(tr("INV_HINT"), 11, K.ASH_LT)
	hint.name = "Hint"
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(hint)
	col.add_child(head)
	_equip_row = K.hbox(10)
	col.add_child(_equip_row)
	var sep := ColorRect.new()
	sep.color = K.SLATE_2
	sep.custom_minimum_size = Vector2(0, 1)
	col.add_child(sep)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 3)
	_grid.add_theme_constant_override("v_separation", 3)
	col.add_child(_grid)
	_tooltip = K.panel(8, K.SLATE_4)
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_tooltip)
	_tooltip_box = K.vbox(2)
	_tooltip.add_child(_tooltip_box)


func _on_run_started() -> void:
	RunManager.inventory.inventory_changed.connect(_refresh)
	RunManager.equipment.equipment_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not get_tree().paused:
		_root.visible = not _root.visible
		if _root.visible:
			(_panel.find_child("Title", true, false) as Label).text = tr("INV_TITLE")
			(_panel.find_child("Hint", true, false) as Label).text = tr("INV_HINT")
			_refresh()
		else:
			_tooltip.visible = false


func _refresh() -> void:
	if RunManager.inventory == null or not is_instance_valid(RunManager.inventory):
		return
	for c in _equip_row.get_children():
		c.queue_free()
	for slot_name in EQUIP_SLOT_NAMES:
		var item: ItemData = _get_equipped(slot_name)
		var v := K.vbox(2)
		var b := _slot(item, 1, K.item_color(item.rarity) if item != null else K.SLATE_3)
		b.pressed.connect(_on_equipment_slot_pressed.bind(slot_name))
		if item != null:
			b.mouse_entered.connect(_show_tooltip.bind(item, b))
			b.mouse_exited.connect(_hide_tooltip)
		v.add_child(b)
		var l := K.num(tr(EQUIP_KEYS[slot_name]), 10, K.ASH_LT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		_equip_row.add_child(v)

	for c in _grid.get_children():
		c.queue_free()
	var inv := RunManager.inventory
	for i in range(inv.capacity):
		if i < inv.slots.size():
			var slot: Dictionary = inv.slots[i]
			var item: ItemData = slot["item"]
			var b := _slot(item, slot["count"], K.SLATE_3)
			b.pressed.connect(_on_inventory_slot_pressed.bind(item))
			b.mouse_entered.connect(_show_tooltip.bind(item, b))
			b.mouse_exited.connect(_hide_tooltip)
			b.gui_input.connect(_on_inventory_slot_gui_input.bind(item))
			_grid.add_child(b)
		else:
			_grid.add_child(_slot(null, 0, K.SLATE_2))


func _slot(item: ItemData, count: int, border: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = SLOT
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", K.frame(K.SOOT, border, 1, 0))
	b.add_theme_stylebox_override("hover", K.frame(K.SLATE_1, K.GOLD, 1, 0))
	b.add_theme_stylebox_override("pressed", K.frame(K.SLATE_1, K.GOLD_LT, 1, 0))
	b.add_theme_stylebox_override("disabled", K.frame(K.SOOT, border, 1, 0))
	if item == null:
		b.disabled = true
		return b
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := K.icon(item.icon)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ic)
	b.add_child(holder)
	if count > 1:
		var n := K.shadowed(K.num(str(count), 11, K.PARCH))
		n.position = Vector2(SLOT.x - 8, SLOT.y - 12)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(n)
	return b


func _get_equipped(slot_name: String) -> ItemData:
	var eq := RunManager.equipment
	if eq == null:
		return null
	match slot_name:
		"weapon":
			return eq.get_weapon()
		"head":
			return eq.head
		"chest":
			return eq.chest
		"feet":
			return eq.feet
	return null


func _on_inventory_slot_pressed(item: ItemData) -> void:
	_hide_tooltip()
	if item is WeaponData or item is ArmorData:
		var old := RunManager.equipment.equip(item)
		RunManager.inventory.remove_item(item, 1)
		if old != null:
			RunManager.inventory.add_item(old, 1)
	elif item is ConsumableData:
		_use_consumable(item)


func _on_inventory_slot_gui_input(event: InputEvent, item: ItemData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var earned := RunManager.inventory.convert_to_currency(item, 1)
		if earned > 0:
			GameManager.add_currency(earned)
			_hide_tooltip()


func _use_consumable(item: ConsumableData) -> void:
	if item.effect == ConsumableData.Effect.HEAL:
		var player := get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
		if player != null:
			var health: HealthComponent = player.get_node("HealthComponent")
			health.heal(item.value)
	RunManager.inventory.remove_item(item, 1)


func _on_equipment_slot_pressed(slot_name: String) -> void:
	_hide_tooltip()
	var old := RunManager.equipment.unequip(slot_name)
	if old != null:
		RunManager.inventory.add_item(old, 1)


func _show_tooltip(item: ItemData, btn: Control) -> void:
	for c in _tooltip_box.get_children():
		c.queue_free()
	_tooltip_box.add_child(K.label(item.get_name_text(), 11, K.item_color(item.rarity), K.font_medium()))
	_tooltip_box.add_child(K.num(item.get_rarity_name().to_upper(), 10, K.item_color(item.rarity)))
	for line in item.get_stat_lines():
		_tooltip_box.add_child(K.num(line, 11, K.PARCH))
	var delta := _get_equip_delta_line(item)
	if delta != "":
		_tooltip_box.add_child(K.num(delta, 11, K.GOLD))
	var desc := item.get_desc_text()
	if desc != "":
		var d := K.label(desc, 9, K.BONE)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(120, 0)
		_tooltip_box.add_child(d)
	_tooltip_box.add_child(K.num(tr("INV_SELL") % item.get_sell_value(), 10, K.ASH_LT))
	_tooltip.reset_size()
	_tooltip.position = Vector2(_panel.position.x + _panel.size.x + 6, btn.global_position.y)
	_tooltip.visible = true


func _get_equip_delta_line(item: ItemData) -> String:
	if item is WeaponData:
		var current := RunManager.equipment.get_weapon()
		var now: float = current.damage if current else 0.0
		return tr("INV_DELTA_DAMAGE") % [now, item.damage]
	if item is ArmorData:
		var cur: ItemData = _get_equipped(_armor_slot_name(item.slot))
		var now: float = cur.defense if cur else 0.0
		return tr("INV_DELTA_DEFENSE") % [now, item.defense]
	return ""


func _armor_slot_name(slot: ArmorData.Slot) -> String:
	match slot:
		ArmorData.Slot.HEAD:
			return "head"
		ArmorData.Slot.FEET:
			return "feet"
		_:
			return "chest"


func _hide_tooltip() -> void:
	_tooltip.visible = false

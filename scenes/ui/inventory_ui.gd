## InventoryUI — "I" tuşuyla açılıp kapanan basit envanter ekranı.
## Veri kaynağı RunManager.inventory / RunManager.equipment (Faz 6) — bu
## sayede kat geçişlerinde Player yeniden oluşsa da envanter durumu kaybolmaz.
## UI tamamen sinyal güdümlü: kendi state'ini tutmaz, her `inventory_changed`/
## `equipment_changed`'da yeniden çizilir (roadmap'in "UI veriye sıkı
## bağlanmasın" uyarısına uygun).
##
## Sahne ağacı _ready() çağrıları çocuktan ebeveyne doğru yapılır — InventoryUI
## (Main'in çocuğu) _ready() olduğunda Main._ready() henüz çalışmamıştır, yani
## RunManager.start_run() (ve onun kurduğu inventory/equipment) henüz yok.
## Bu yüzden RunManager.inventory'e doğrudan _ready()'de bağlanmak yerine
## EventBus.run_started'ı dinleyip component'lere o sinyal geldiğinde
## bağlanıyoruz (EventBus zaten her zaman hazır bir autoload).
class_name InventoryUI
extends CanvasLayer

const SLOT_SIZE := Vector2(28, 28)
const EQUIP_SLOT_NAMES: Array[String] = ["weapon", "head", "chest", "feet"]
const EQUIP_SLOT_LABELS := {
	"weapon": "Silah",
	"head": "Baş",
	"chest": "Gövde",
	"feet": "Ayak",
}

var _equipment_buttons: Dictionary = {}

@onready var root_control: Control = $Control
@onready var inv_panel: Control = $Control/Panel
@onready var equipment_row: HBoxContainer = $Control/Panel/VBoxContainer/EquipmentRow
@onready var slot_grid: GridContainer = $Control/Panel/VBoxContainer/SlotGrid
@onready var tooltip: Panel = $Control/Tooltip
@onready var tooltip_label: Label = $Control/Tooltip/TooltipLabel


func _ready() -> void:
	root_control.visible = false
	tooltip.visible = false
	_build_equipment_slots()
	EventBus.run_started.connect(_on_run_started)
	if RunManager.inventory != null:
		_on_run_started()


## RunManager yeni bir run kurduğunda (start_run -> _setup_run_state) emit
## edilir; component referansları burada tazelenip sinyallere bağlanılır.
## BUG FİX: RunManager her yeni run'da inventory/equipment'i sıfırdan
## (yeni instance) kurar ve eskisini queue_free eder (bkz. run_manager.gd
## _setup_run_state). Bu yüzden burada eski instance'tan disconnect denemek
## ("Attempt to disconnect a nonexistent connection" hatası — eski bağlantı
## zaten eski/silinen instance'ta, RunManager.inventory artık YENİ instance'ı
## gösteriyor) hem hataya hem de fonksiyonun ortasında durup asıl connect
## satırlarının hiç çalışmamasına yol açıyordu. Eski bağlantı, eski instance
## queue_free olunca kendiliğinden düşer — manuel disconnect'e gerek yok.
func _on_run_started() -> void:
	RunManager.inventory.inventory_changed.connect(_refresh_inventory)
	RunManager.equipment.equipment_changed.connect(_refresh_equipment)

	_refresh_equipment()
	_refresh_inventory()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		root_control.visible = not root_control.visible
		if root_control.visible:
			_refresh_equipment()
			_refresh_inventory()
		else:
			tooltip.visible = false


func _build_equipment_slots() -> void:
	for child in equipment_row.get_children():
		child.queue_free()
	_equipment_buttons.clear()

	for slot_name in EQUIP_SLOT_NAMES:
		var btn := Button.new()
		btn.custom_minimum_size = SLOT_SIZE
		btn.text = EQUIP_SLOT_LABELS[slot_name].substr(0, 1)
		btn.pressed.connect(_on_equipment_slot_pressed.bind(slot_name))
		btn.mouse_entered.connect(_on_equipment_slot_hover.bind(slot_name, btn))
		btn.mouse_exited.connect(_hide_tooltip)
		equipment_row.add_child(btn)
		_equipment_buttons[slot_name] = btn


func _refresh_equipment() -> void:
	for slot_name in EQUIP_SLOT_NAMES:
		var item: ItemData = _get_equipped(slot_name)
		var btn: Button = _equipment_buttons[slot_name]
		if item != null:
			btn.icon = item.icon
			btn.text = ""
			btn.modulate = item.get_color()
		else:
			btn.icon = null
			btn.text = EQUIP_SLOT_LABELS[slot_name].substr(0, 1)
			btn.modulate = Color.WHITE


func _refresh_inventory() -> void:
	for child in slot_grid.get_children():
		child.queue_free()

	var inv := RunManager.inventory
	for i in range(inv.capacity):
		var btn := Button.new()
		btn.custom_minimum_size = SLOT_SIZE

		if i < inv.slots.size():
			var slot: Dictionary = inv.slots[i]
			var item: ItemData = slot["item"]
			var count: int = slot["count"]
			btn.icon = item.icon
			btn.text = str(count) if count > 1 else ""
			btn.modulate = item.get_color()
			btn.tooltip_text = ""
			btn.pressed.connect(_on_inventory_slot_pressed.bind(item))
			btn.mouse_entered.connect(_on_inventory_slot_hover.bind(item, btn))
			btn.mouse_exited.connect(_hide_tooltip)
			## Faz 8 UX: sağ tık = fazlalık eşyayı kalıcı paraya çevir.
			btn.gui_input.connect(_on_inventory_slot_gui_input.bind(item))

		slot_grid.add_child(btn)


func _get_equipped(slot_name: String) -> ItemData:
	var eq := RunManager.equipment
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


## Silah/zırh ise kuşan (eski parça envantere döner); iksir ise hemen kullan.
func _on_inventory_slot_pressed(item: ItemData) -> void:
	if item is WeaponData or item is ArmorData:
		var old := RunManager.equipment.equip(item)
		RunManager.inventory.remove_item(item, 1)
		if old != null:
			RunManager.inventory.add_item(old, 1)
	elif item is ConsumableData:
		_use_consumable(item)


## Faz 8 UX: sağ tıkla 1 adet eşyayı kalıcı paraya çevir ("fazlalık
## eşyaların meta paraya dönüştürülebilmesi"). Kuşanılı bir parçayı yanlışlıkla
## satmayı önlemek için RunManager.equipment'te kuşanılı olan item'lar
## envanter slotunda hiç yer almaz (equip edilince remove_item çağrılıyor),
## bu yüzden ek bir kontrol gerekmiyor.
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
	var old := RunManager.equipment.unequip(slot_name)
	if old != null:
		RunManager.inventory.add_item(old, 1)


func _on_inventory_slot_hover(item: ItemData, btn: Button) -> void:
	_show_tooltip(item, btn)


func _on_equipment_slot_hover(slot_name: String, btn: Button) -> void:
	var item := _get_equipped(slot_name)
	if item != null:
		_show_tooltip(item, btn)


func _show_tooltip(item: ItemData, btn: Button) -> void:
	var lines: Array[String] = [item.display_name, item.get_rarity_name()]
	lines.append_array(item.get_stat_lines())
	## Faz 8 UX: "Ekipman değişikliklerinin belirgin istatistiksel etkilerinin
	## net gösterilmesi" — kuşanılırsa ne değişeceğini karşılaştırmalı göster.
	var equip_line := _get_equip_delta_line(item)
	if equip_line != "":
		lines.append(equip_line)
	if item.description != "":
		lines.append(item.description)
	## Faz 8 UX: "fazlalık eşyaların meta paraya dönüştürülebilmesi" hatırlatıcısı.
	lines.append("(Sağ tık: %d paraya çevir)" % item.get_sell_value())
	tooltip_label.text = "\n".join(lines)
	## Tooltip'i panelin SAĞINA koy (panel içeriğiyle üst üste binmesin);
	## dikeyde hover edilen butonun hizasında.
	tooltip.global_position = Vector2(
		inv_panel.global_position.x + inv_panel.size.x + 6.0,
		btn.global_position.y
	)
	tooltip.visible = true


## Bu item kuşanılırsa hasar/savunma şu an kuşanılana göre nasıl değişir?
## Karşılaştırma satırı döner, kuşanılabilir değilse "" döner.
func _get_equip_delta_line(item: ItemData) -> String:
	if item is WeaponData:
		var weapon: WeaponData = item
		var current := RunManager.equipment.get_weapon()
		var current_dmg: float = current.damage if current else 0.0
		var delta: float = weapon.damage - current_dmg
		var sign_str := "+" if delta >= 0.0 else ""
		return "Kuşanılırsa hasar: %.0f → %.0f (%s%.0f)" % [current_dmg, weapon.damage, sign_str, delta]
	if item is ArmorData:
		var armor: ArmorData = item
		var current_armor: ItemData = _get_equipped(_armor_slot_name(armor.slot))
		var current_def: float = current_armor.defense if current_armor else 0.0
		var delta: float = armor.defense - current_def
		var sign_str := "+" if delta >= 0.0 else ""
		return "Kuşanılırsa savunma: %.0f → %.0f (%s%.0f)" % [current_def, armor.defense, sign_str, delta]
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
	tooltip.visible = false

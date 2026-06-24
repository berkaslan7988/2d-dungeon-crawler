## InventoryComponent — slot tabanlı envanter. RunManager run başında bir
## instance oluşturup kendine child yapar; böylece kat değişiminde (Player
## yeniden instantiate edilse de) envanter kaybolmaz.
class_name InventoryComponent
extends Node

signal inventory_changed

@export var capacity: int = 20

## Her slot: {"item": ItemData, "count": int}
var slots: Array = []


## Eşyayı stack'lere/yeni slotlara dağıtır. Sığmayan miktarı (leftover)
## döner — 0 ise hepsi sığdı.
func add_item(item: ItemData, count: int = 1) -> int:
	if item == null or count <= 0:
		return count

	var remaining := count
	for slot in slots:
		if remaining <= 0:
			break
		if slot["item"] == item and slot["count"] < item.stack_size:
			var space: int = item.stack_size - slot["count"]
			var added: int = min(space, remaining)
			slot["count"] += added
			remaining -= added

	while remaining > 0 and slots.size() < capacity:
		var added: int = min(item.stack_size, remaining)
		slots.append({"item": item, "count": added})
		remaining -= added

	_notify_changed()
	return remaining


func remove_item(item: ItemData, count: int = 1) -> bool:
	if not has_item(item, count):
		return false

	var needed := count
	for i in range(slots.size() - 1, -1, -1):
		if needed <= 0:
			break
		var slot: Dictionary = slots[i]
		if slot["item"] == item:
			var taken: int = min(int(slot["count"]), needed)
			slot["count"] = int(slot["count"]) - taken
			needed -= taken
			if slot["count"] <= 0:
				slots.remove_at(i)

	_notify_changed()
	return true


## Faz 8 UX: "fazlalık eşyaların meta paraya dönüştürülebilmesi" — count
## adet item'ı envanterden çıkarır, kazanılan kalıcı para miktarını döner
## (item başına item.get_sell_value()). Çağıran taraf (UI) bu miktarı
## GameManager.add_currency()'e iletir — InventoryComponent kendisi
## GameManager'a bağımlı olmasın diye para ekleme işini burada yapmıyoruz.
func convert_to_currency(item: ItemData, count: int = 1) -> int:
	if item == null or count <= 0 or not has_item(item, count):
		return 0
	remove_item(item, count)
	return item.get_sell_value() * count


func get_count(item: ItemData) -> int:
	var total := 0
	for slot in slots:
		if slot["item"] == item:
			total += int(slot["count"])
	return total


func has_item(item: ItemData, count: int = 1) -> bool:
	return get_count(item) >= count


func _notify_changed() -> void:
	inventory_changed.emit()
	EventBus.inventory_changed.emit()

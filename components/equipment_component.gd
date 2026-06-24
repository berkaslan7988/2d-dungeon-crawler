## EquipmentComponent — dört kuşam slotu (weapon/head/chest/feet). equip()
## eski parçayı geri döner ki çağıran (UI) onu envantere koyabilsin.
class_name EquipmentComponent
extends Node

signal equipment_changed

var weapon: WeaponData = null
var head: ArmorData = null
var chest: ArmorData = null
var feet: ArmorData = null


## item kuşanılabilir değilse null döner (hiçbir şey değişmez).
## Kuşanılabilirse önceki parçayı (varsa) döner, yoksa null döner.
func equip(item: ItemData) -> ItemData:
	var old: ItemData = null

	if item is WeaponData:
		old = weapon
		weapon = item
	elif item is ArmorData:
		match item.slot:
			ArmorData.Slot.HEAD:
				old = head
				head = item
			ArmorData.Slot.CHEST:
				old = chest
				chest = item
			ArmorData.Slot.FEET:
				old = feet
				feet = item
	else:
		return null

	equipment_changed.emit()
	return old


func unequip(slot_name: String) -> ItemData:
	var old: ItemData = null
	match slot_name:
		"weapon":
			old = weapon
			weapon = null
		"head":
			old = head
			head = null
		"chest":
			old = chest
			chest = null
		"feet":
			old = feet
			feet = null

	if old != null:
		equipment_changed.emit()
	return old


func get_weapon() -> WeaponData:
	return weapon


func get_all_armor() -> Array[ArmorData]:
	var result: Array[ArmorData] = []
	if head != null:
		result.append(head)
	if chest != null:
		result.append(chest)
	if feet != null:
		result.append(feet)
	return result

## ArmorData — kuşanılınca StatsComponent'e savunma ve isteğe bağlı bonus
## (can/hız) ekler. `slot` aynı slota ikinci parça kuşanmayı önlemek için
## EquipmentComponent tarafından kullanılır.
class_name ArmorData
extends ItemData

enum Slot { HEAD, CHEST, FEET }

@export var slot: Slot = Slot.CHEST
@export var defense: float = 2.0
@export var max_health_bonus: float = 0.0
@export var move_speed_bonus: float = 0.0


func _init() -> void:
	item_type = ItemType.ARMOR


func get_stat_lines() -> Array[String]:
	var lines: Array[String] = [TranslationServer.translate("STAT_DEFENSE") % defense]
	if max_health_bonus != 0.0:
		lines.append(TranslationServer.translate("STAT_LIFE") % max_health_bonus)
	if move_speed_bonus != 0.0:
		lines.append(TranslationServer.translate("STAT_SPEED") % move_speed_bonus)
	return lines

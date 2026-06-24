## WeaponData — kuşanılınca oyuncunun HitboxComponent değerlerini etkiler
## (StatsComponent üzerinden). item_type her zaman WEAPON olmalı.
class_name WeaponData
extends ItemData

@export var damage: float = 5.0
@export var attack_speed: float = 1.0  ## Saldırı hızı çarpanı (1.0 = normal).
@export var knockback: float = 0.0     ## Taban knockback'e eklenir.
@export var range_bonus: float = 0.0   ## Saldırı menziline eklenir (piksel).


func _init() -> void:
	item_type = ItemType.WEAPON


func get_stat_lines() -> Array[String]:
	return [
		"Hasar: +%.0f" % damage,
		"Saldırı Hızı: x%.2f" % attack_speed,
		"Geri Tepme: +%.0f" % knockback,
	]

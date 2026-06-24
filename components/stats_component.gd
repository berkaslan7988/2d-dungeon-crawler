## StatsComponent — taban istatistik + ekipman bonuslarını + run-içi upgrade
## bonuslarını toplayıp "efektif" değerleri hesaplar.
##
## Ekipman değişince (equipment_changed) veya upgrade uygulanınca kendi
## `stats_changed` sinyalini yayar; Player bu sinyale bağlanıp
## Hitbox/Health gibi gerçek oyun değerlerini günceller.
##
## Faz 7: upgrade_bonuses dizisi eklendi. clear_upgrades() ile run başında
## sıfırlanır, apply_upgrade() ile yeni upgrade eklenir.
class_name StatsComponent
extends Node

signal stats_changed

## Faz 4'teki sabit Hitbox değeriyle eşleşir (ekipmansız davranış değişmesin).
@export var base_damage: float = 15.0
@export var base_defense: float = 0.0
@export var base_max_health: float = 100.0
@export var base_move_speed: float = 90.0
@export var base_attack_speed: float = 1.0

var equipment: EquipmentComponent = null

## Faz 7: run-içi upgrade bonusları. Her eleman bir Dictionary:
## { "type": UpgradeData.UpgradeType, "value": float }
## clear_upgrades() ile run başında temizlenir.
var upgrade_bonuses: Array[Dictionary] = []

## Faz 7: bu run'da aktif life_steal oranı (0.0 = yok).
var life_steal_ratio: float = 0.0


func bind_equipment(eq: EquipmentComponent) -> void:
	equipment = eq
	equipment.equipment_changed.connect(_on_equipment_changed)


## Faz 7: bir UpgradeData'yı kalıcı olarak bu run'a ekler.
func apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.upgrade_type:
		UpgradeData.UpgradeType.LIFE_STEAL:
			life_steal_ratio += upgrade.value
		_:
			upgrade_bonuses.append({
				"type": upgrade.upgrade_type,
				"value": upgrade.value,
			})
	stats_changed.emit()


## Faz 7: run başında (start_run) tüm upgrade bonuslarını sıfırlar.
func clear_upgrades() -> void:
	upgrade_bonuses.clear()
	life_steal_ratio = 0.0
	stats_changed.emit()


## --- Efektif değer hesapları ---

func get_damage() -> float:
	var total := base_damage
	var w := equipment.get_weapon() if equipment else null
	if w:
		total += w.damage
	for b in upgrade_bonuses:
		match b["type"]:
			UpgradeData.UpgradeType.DAMAGE_FLAT:
				total += b["value"]
			UpgradeData.UpgradeType.DAMAGE_PERCENT:
				total *= (1.0 + b["value"])
	return total


func get_attack_speed() -> float:
	var total := base_attack_speed
	var w := equipment.get_weapon() if equipment else null
	if w:
		total *= w.attack_speed
	for b in upgrade_bonuses:
		if b["type"] == UpgradeData.UpgradeType.ATTACK_SPEED:
			total *= (1.0 + b["value"])
	return total


func get_knockback_bonus() -> float:
	var w := equipment.get_weapon() if equipment else null
	return w.knockback if w else 0.0


func get_range_bonus() -> float:
	var w := equipment.get_weapon() if equipment else null
	return w.range_bonus if w else 0.0


func get_defense() -> float:
	var total := base_defense
	if equipment:
		for armor in equipment.get_all_armor():
			total += armor.defense
	for b in upgrade_bonuses:
		if b["type"] == UpgradeData.UpgradeType.DEFENSE_FLAT:
			total += b["value"]
	return total


func get_max_health() -> float:
	var total := base_max_health
	if equipment:
		for armor in equipment.get_all_armor():
			total += armor.max_health_bonus
	for b in upgrade_bonuses:
		if b["type"] == UpgradeData.UpgradeType.HEALTH_FLAT:
			total += b["value"]
	## Faz 10: yüzde bonuslar flat'ten SONRA uygulanır (taban+flat üzerine).
	for b in upgrade_bonuses:
		if b["type"] == UpgradeData.UpgradeType.HEALTH_PERCENT:
			total *= (1.0 + b["value"])
	return total


func get_move_speed() -> float:
	var total := base_move_speed
	if equipment:
		for armor in equipment.get_all_armor():
			total += armor.move_speed_bonus
	for b in upgrade_bonuses:
		if b["type"] == UpgradeData.UpgradeType.SPEED_FLAT:
			total += b["value"]
	## Faz 10: yüzde hız bonusu.
	for b in upgrade_bonuses:
		if b["type"] == UpgradeData.UpgradeType.SPEED_PERCENT:
			total *= (1.0 + b["value"])
	return total


## Faz 7: Dash cooldown çarpanı (1.0 = değişiklik yok, 0.75 = -%25 cooldown).
func get_dash_cooldown_multiplier() -> float:
	var mult := 1.0
	for b in upgrade_bonuses:
		if b["type"] == UpgradeData.UpgradeType.DASH_COOLDOWN:
			mult *= (1.0 - b["value"])
	return max(mult, 0.1)  # minimum %10 cooldown kalır


## Çarpan tabanlı hasar azaltma (roadmap önerisi — yüksek savunmada daha
## dengeli ölçeklenir, sıfıra bölme/eksi hasar riski yok):
## final = ham_hasar * 100 / (100 + savunma)
static func apply_defense(raw_damage: float, defense: float) -> float:
	return raw_damage * (100.0 / (100.0 + max(defense, 0.0)))


func _on_equipment_changed() -> void:
	stats_changed.emit()

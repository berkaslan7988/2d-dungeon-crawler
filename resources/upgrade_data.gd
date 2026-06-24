## UpgradeData — run-içi upgrade kartlarını tanımlayan veri kaynağı.
## Her upgrade bir .tres dosyası olarak kaydedilir; Inspector'dan düzenlenir.
## apply() metodunu ÇAĞIRMA — bunun yerine StatsComponent.apply_upgrade() kullan.
## UpgradeType.LIFE_STEAL özel: Player tarafından _on_hurtbox_damaged'da işlenir.
class_name UpgradeData
extends Resource

enum UpgradeType {
	DAMAGE_FLAT,       ## +sabit hasar
	DAMAGE_PERCENT,    ## +% hasar çarpanı (0.15 = +%15)
	HEALTH_FLAT,       ## +sabit max can
	SPEED_FLAT,        ## +sabit hareket hızı
	ATTACK_SPEED,      ## +% saldırı hızı çarpanı (0.20 = +%20)
	DEFENSE_FLAT,      ## +sabit savunma
	LIFE_STEAL,        ## % hasar → can (0.10 = %10)
	DASH_COOLDOWN,     ## -%  dash cooldown çarpanı (0.25 = -%25)
	HEALTH_PERCENT,    ## +% max can (0.20 = +%20) — Faz 10
	SPEED_PERCENT,     ## +% hareket hızı (0.15 = +%15) — Faz 10
}

enum Rarity { COMMON, UNCOMMON, RARE }

@export_group("Görünüm")
@export var id: StringName
@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON

@export_group("Mekanik")
@export var upgrade_type: UpgradeType = UpgradeType.DAMAGE_FLAT
@export var value: float = 5.0
## Ağırlıklı seçim için: yüksek weight = daha sık çıkar.
@export var weight: float = 10.0

@export_group("Mağaza (Kalıcı)")
## >0 ise bu upgrade meta mağazada (PauseMenu) kalıcı para ile satın alınabilir
## ve GameManager.purchased_meta_upgrades'e kaydedilip her run başında otomatik
## uygulanır. 0 ise normal run-içi upgrade havuzunda kalır, mağazada görünmez.
@export var meta_cost: int = 0

const RARITY_COLORS: Dictionary = {
	Rarity.COMMON:   Color("c8c8c8"),
	Rarity.UNCOMMON: Color("4caf50"),
	Rarity.RARE:     Color("2196f3"),
}

func get_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

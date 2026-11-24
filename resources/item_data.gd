## ItemData — envanterdeki her eşyanın temel veri sözleşmesi. WeaponData/
## ArmorData/ConsumableData bunu extend eder. Tamamen Resource tabanlı —
## yeni eşya eklemek için Inspector'dan .tres oluşturmak yeterli, kod
## yazmaya gerek yok.
class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, WEAPON, ARMOR, MATERIAL }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Iron, bronze, gold, then arcane and ember for the two highest tiers.
const RARITY_COLORS := {
	Rarity.COMMON: Color("8f90a6"),
	Rarity.UNCOMMON: Color("9c6a3e"),
	Rarity.RARE: Color("f5b84a"),
	Rarity.EPIC: Color("b79cf2"),
	Rarity.LEGENDARY: Color("ec7a2a"),
}

const RARITY_NAMES := {
	Rarity.COMMON: "RARITY_COMMON",
	Rarity.UNCOMMON: "RARITY_UNCOMMON",
	Rarity.RARE: "RARITY_RARE",
	Rarity.EPIC: "RARITY_EPIC",
	Rarity.LEGENDARY: "RARITY_LEGENDARY",
}

## Faz 8 UX: "fazlalık eşyaların meta paraya dönüştürülebilmesi" — rarity'ye
## göre sabit bir taban satış değeri. İleride item başına override edilebilir.
const RARITY_SELL_VALUES := {
	Rarity.COMMON: 2,
	Rarity.UNCOMMON: 5,
	Rarity.RARE: 12,
	Rarity.EPIC: 25,
	Rarity.LEGENDARY: 50,
}

@export var id: StringName = &""
@export var display_name: String = "Eşya"
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export var stack_size: int = 1


func get_color() -> Color:
	return RARITY_COLORS[rarity]


func get_rarity_name() -> String:
	return TranslationServer.translate(RARITY_NAMES[rarity])


## Localised name (ITEM_<ID>_NAME), falling back to display_name.
func get_name_text() -> String:
	return _tr_or("ITEM_%s_NAME" % String(id).to_upper(), display_name)


func get_desc_text() -> String:
	return _tr_or("ITEM_%s_DESC" % String(id).to_upper(), description)


static func _tr_or(key: String, fallback: String) -> String:
	var s := TranslationServer.translate(key)
	return fallback if s == key else s


## Faz 8 UX: bu eşyanın bir biriminin kalıcı para karşılığı (envanterde
## "paraya çevir" için).
func get_sell_value() -> int:
	return RARITY_SELL_VALUES[rarity]


## Tooltip'te gösterilecek ek istatistik satırları. Alt sınıflar override eder.
func get_stat_lines() -> Array[String]:
	return []

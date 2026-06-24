## ItemData — envanterdeki her eşyanın temel veri sözleşmesi. WeaponData/
## ArmorData/ConsumableData bunu extend eder. Tamamen Resource tabanlı —
## yeni eşya eklemek için Inspector'dan .tres oluşturmak yeterli, kod
## yazmaya gerek yok.
class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, WEAPON, ARMOR, MATERIAL }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const RARITY_COLORS := {
	Rarity.COMMON: Color.WHITE,
	Rarity.UNCOMMON: Color("4caf50"),
	Rarity.RARE: Color("2196f3"),
	Rarity.EPIC: Color("9c27b0"),
	Rarity.LEGENDARY: Color("ff9800"),
}

const RARITY_NAMES := {
	Rarity.COMMON: "Sıradan",
	Rarity.UNCOMMON: "Nadide",
	Rarity.RARE: "Nadir",
	Rarity.EPIC: "Epik",
	Rarity.LEGENDARY: "Efsanevi",
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
	return RARITY_NAMES[rarity]


## Faz 8 UX: bu eşyanın bir biriminin kalıcı para karşılığı (envanterde
## "paraya çevir" için).
func get_sell_value() -> int:
	return RARITY_SELL_VALUES[rarity]


## Tooltip'te gösterilecek ek istatistik satırları. Alt sınıflar override eder.
func get_stat_lines() -> Array[String]:
	return []

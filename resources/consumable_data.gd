## ConsumableData — kullanılınca anlık bir etki uygular (can yenileme vb.)
## ve envanterden bir adet düşer. `effect` ileride buff türleriyle
## genişletilebilir; şimdilik HEAL yeterli (roadmap Faz 6 kapsamı).
class_name ConsumableData
extends ItemData

enum Effect { HEAL, BUFF }

@export var effect: Effect = Effect.HEAL
@export var value: float = 20.0


func _init() -> void:
	item_type = ItemType.CONSUMABLE


func get_stat_lines() -> Array[String]:
	match effect:
		Effect.HEAL:
			return [TranslationServer.translate("STAT_HEAL") % value]
		Effect.BUFF:
			return [TranslationServer.translate("STAT_BUFF") % value]
	return []

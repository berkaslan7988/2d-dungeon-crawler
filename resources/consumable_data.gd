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
			return ["İyileştirme: +%.0f can" % value]
		Effect.BUFF:
			return ["Güçlendirme: +%.0f" % value]
	return []

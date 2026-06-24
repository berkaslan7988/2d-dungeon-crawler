## LootEntry — bir LootTable satırı: hangi eşya, ağırlığı (olasılık payı)
## ve düşen adet aralığı.
class_name LootEntry
extends Resource

@export var item: ItemData
@export var weight: float = 1.0
@export var min_amount: int = 1
@export var max_amount: int = 1

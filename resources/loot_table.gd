## LootTable — ağırlıklı (weighted) düşme tablosu. roll() çağrıldığında
## ağırlıklara göre TEK bir LootEntry seçilir ve o satırın
## min/max_amount aralığında rastgele adette eşya döner.
## (Çoklu-drop istenirse roll() birden çok kez çağrılabilir.)
class_name LootTable
extends Resource

@export var entries: Array[LootEntry] = []


func roll(rng: RandomNumberGenerator) -> Array[ItemData]:
	var result: Array[ItemData] = []
	if entries.is_empty():
		return result

	var total_weight := 0.0
	for e in entries:
		total_weight += e.weight
	if total_weight <= 0.0:
		return result

	var pick := rng.randf() * total_weight
	var acc := 0.0
	for e in entries:
		acc += e.weight
		if pick <= acc:
			var count := rng.randi_range(e.min_amount, e.max_amount)
			for i in count:
				result.append(e.item)
			break
	return result

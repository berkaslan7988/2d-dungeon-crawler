## UpgradePool — run-içi upgrade havuzunu tutar ve ağırlıklı rastgele seçim yapar.
## Tek bir .tres dosyası olarak kaydedilir; Inspector'dan upgrade eklenip çıkarılabilir.
class_name UpgradePool
extends Resource

@export var upgrades: Array[UpgradeData] = []


## count kadar birbirinden farklı upgrade seçeneği döndürür (ağırlıklı rastgele).
## exclude listesindeki id'ler bu turda çıkmaz (ör. daha önce seçilenler).
func roll_choices(rng: RandomNumberGenerator, count: int = 3,
		exclude: Array = []) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for u in upgrades:
		if not exclude.has(u.id):
			pool.append(u)

	if pool.is_empty():
		return []

	var chosen: Array[UpgradeData] = []
	var remaining := pool.duplicate()

	for _i in count:
		if remaining.is_empty():
			break
		var total_weight := 0.0
		for u in remaining:
			total_weight += u.weight

		var pick := rng.randf() * total_weight
		var acc := 0.0
		for u in remaining:
			acc += u.weight
			if pick <= acc:
				chosen.append(u)
				remaining.erase(u)
				break

	return chosen

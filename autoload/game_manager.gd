## GameManager — üst düzey oyun durumu (menü/oyun/duraklat), sahne geçişleri
## ve kalıcı meta ilerleme yönetimi. Autoload adı: GameManager
##
## Faz 0: iskelet (State enum + change_scene).
## Faz 7: meta ilerleme eklendi — kalıcı para, istatistikler, save/load.
##   Meta verileri oyun başında SaveManager'dan okunur;
##   run bitişinde (EventBus.run_ended) otomatik kaydedilir.
extends Node

enum State { MENU, PLAYING, PAUSED }

var state: State = State.MENU

## --- Meta ilerleme (Faz 7) ---
var meta_currency: int = 0   ## Kalıcı para (ruh, taş vb. — run'lar arası birikir)
var total_runs: int = 0      ## Toplam tamamlanan run sayısı
var best_floor: int = 0      ## Ulaşılan en yüksek kat
var last_run_reward: int = 0 ## Son run sonunda kazanılan ruh (DeathScreen okur)

## --- Meta mağaza (PauseMenu'den kalıcı para ile satın alınan upgrade'ler) ---
## Satın alınan UpgradeData.id'lerin (String) listesi. RunManager her run
## başında bu listeyi okuyup ilgili upgrade'leri otomatik uygular.
var purchased_meta_upgrades: Array[String] = []
var meta_shop_pool: UpgradePool = null
const META_SHOP_POOL_PATH: String = "res://data/upgrades/meta_shop_pool.tres"


func _ready() -> void:
	_load_meta()
	_load_meta_shop_pool()
	EventBus.run_ended.connect(_on_run_ended)


## --- Durum & Sahne ---

func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func set_state(new_state: State) -> void:
	state = new_state


## --- Meta Para ---

## amount kadar kalıcı para ekler ve anında kaydeder.
func add_currency(amount: int) -> void:
	meta_currency += amount
	EventBus.meta_currency_changed.emit(meta_currency)
	_save_meta()


## Yeterli para varsa harcar (true döner) ve kaydeder; değilse false döner.
func spend_currency(cost: int) -> bool:
	if meta_currency < cost:
		return false
	meta_currency -= cost
	EventBus.meta_currency_changed.emit(meta_currency)
	_save_meta()
	return true


## --- Meta Mağaza (kalıcı upgrade satın alma) ---

func _load_meta_shop_pool() -> void:
	if ResourceLoader.exists(META_SHOP_POOL_PATH):
		meta_shop_pool = load(META_SHOP_POOL_PATH)
	else:
		push_warning("GameManager: meta_shop_pool.tres bulunamadı (%s)." % META_SHOP_POOL_PATH)


func is_meta_upgrade_purchased(upgrade_id: StringName) -> bool:
	return purchased_meta_upgrades.has(String(upgrade_id))


## Satın alma başarılıysa true döner (para harcanır, kaydedilir).
## Zaten alınmışsa veya para yetmiyorsa false döner.
func purchase_meta_upgrade(upgrade: UpgradeData) -> bool:
	if upgrade == null or is_meta_upgrade_purchased(upgrade.id):
		return false
	if not spend_currency(upgrade.meta_cost):
		return false
	purchased_meta_upgrades.append(String(upgrade.id))
	_save_meta()
	return true


## RunManager._setup_run_state() bu listeyi okuyup her run başında
## StatsComponent.apply_upgrade() ile kalıcı bonusları yeniden uygular.
func get_purchased_meta_upgrades() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	if meta_shop_pool == null:
		return result
	for u in meta_shop_pool.upgrades:
		if is_meta_upgrade_purchased(u.id):
			result.append(u)
	return result


## --- Save / Load ---

func _load_meta() -> void:
	var data: Dictionary = SaveManager.load_meta()
	meta_currency = data.get("currency", 0)
	total_runs    = data.get("total_runs", 0)
	best_floor    = data.get("best_floor", 0)
	## Backward-compatible: eski save'lerde bu alan yok, get() varsayılan []
	## döner. Array[String] tipine güvenle dönüştürülür.
	var purchased: Array = data.get("purchased_meta_upgrades", [])
	purchased_meta_upgrades.clear()
	for id in purchased:
		purchased_meta_upgrades.append(String(id))


func _save_meta() -> void:
	SaveManager.save_meta({
		"currency":   meta_currency,
		"total_runs": total_runs,
		"best_floor": best_floor,
		"purchased_meta_upgrades": purchased_meta_upgrades,
	})


## --- Run Sonu ---

## Bir run'ın kalıcı para ödülü. Tek kaynak — hem _on_run_ended hem
## DeathScreen özeti bunu kullanır (formül tekrarı olmasın).
func calc_run_reward(reached_floor: int, victory: bool) -> int:
	return reached_floor * 10 + (50 if victory else 0)


func _on_run_ended(victory: bool) -> void:
	total_runs += 1
	var reached_floor: int = RunManager.current_floor
	if reached_floor > best_floor:
		best_floor = reached_floor

	## Para: kat sayısına göre ödül (ileride zorluk çarpanı eklenebilir).
	var earned: int = calc_run_reward(reached_floor, victory)
	last_run_reward = earned
	meta_currency += earned
	EventBus.meta_currency_changed.emit(meta_currency)

	_save_meta()
	print("GameManager: run bitti — victory=%s, floor=%d, earned=%d ruh, toplam=%d" \
			% [str(victory), reached_floor, earned, meta_currency])

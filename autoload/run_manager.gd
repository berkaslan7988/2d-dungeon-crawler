## RunManager — bir "run"un (oyun oturumunun) yaşam döngüsünü yönetir.
## Hangi kattayız, hangi seed kullanılıyor ve mevcut kat sahnesinin
## yüklenip/boşaltılması bu autoload'un sorumluluğunda.
##
## Faz 6: Inventory/Equipment/Stats component'leri de burada (RunManager'a
## child olarak) yaşar. Sebep: Player her kat geçişinde DungeonScene içinde
## yeniden instantiate ediliyor (bkz. _load_floor) — envanter/ekipman Player
## üzerinde olsaydı her kat geçişinde sıfırlanırdı. RunManager ise run
## boyunca hiç yok edilmediği için "run-içi kalıcı" durumun doğal evi.
##
## Faz 7: XP/level sistemi, upgrade seçimi (offer/confirm), run sonu
## (end_run) ve düşman XP bağlantısı eklendi.
## Faz 8: enemies_killed sayıcısı eklendi (DeathScreen özeti için).
##
## ÖNEMLİ: go_to_next_floor() genelde bir Area2D body_entered sinyali
## (çıkışa basma) içinden çağrılır — yani fizik motoru hâlâ o frame'in
## çarpışma sorgularını "flush" ederken. O an add_child/queue_free ile
## sahne ağacını değiştirmek Godot'ta hataya yol açar ("flushing queries").
## Bu yüzden gerçek yükleme call_deferred ile bir sonraki güvenli ana ertelenir.
extends Node

const DUNGEON_SCENE: PackedScene = preload("res://scenes/world/DungeonScene.tscn")
const FLOOR_SEED_STRIDE: int = 7919

## --- Kat & seed ---
var current_floor: int = 0
var run_seed: int = 0

## --- Run-içi bileşenler (Faz 6) ---
var inventory: InventoryComponent = null
var equipment: EquipmentComponent = null
var stats: StatsComponent = null

## --- XP & Level (Faz 7) ---
var xp: int = 0
var level: int = 1
var xp_to_next: int = 100

## --- İstatistikler (Faz 8) ---
var enemies_killed: int = 0

## Faz 8 UX: ölüm/zafer ekranı için run süresi ("süre" roadmap'te
## açıkça listelenen bir özet alanı). start_run()'da sıfırlanır.
var _run_start_msec: int = 0

## --- Upgrade sistemi (Faz 7) ---
## Upgrade pool'u res:// yolundan yükleriz. Dosya henüz yoksa null kalır
## ve _load_upgrade_pool() uyarı basar — oyun çökmez.
var upgrade_pool: UpgradePool = null
## Bu run'da seçilen upgrade'ler (debug/istatistik için).
var selected_upgrades: Array[UpgradeData] = []
## offer_upgrades() tarafından sunulan mevcut 3 seçenek.
var _pending_choices: Array[UpgradeData] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## --- Sahne yönetimi ---
var _floor_parent: Node = null
var _current_floor_instance: Node = null

## Upgrade pool'unun res:// yolu. Faz 7 bitince bu .tres oluşturulmuş olacak.
const UPGRADE_POOL_PATH: String = "res://data/upgrades/upgrade_pool.tres"


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	_load_upgrade_pool()


## --- Genel API ---

func set_floor_parent(parent: Node) -> void:
	_floor_parent = parent


func start_run(seed_value: int = -1) -> void:
	run_seed = seed_value if seed_value >= 0 else randi()
	_rng.seed = run_seed
	current_floor = 1
	_reset_xp()
	enemies_killed = 0
	selected_upgrades.clear()
	_run_start_msec = Time.get_ticks_msec()
	_setup_run_state()
	EventBus.run_started.emit()
	call_deferred("_load_floor")


## Faz 8 UX: ölüm/zafer ekranı için run süresi (saniye).
func get_run_duration() -> float:
	return (Time.get_ticks_msec() - _run_start_msec) / 1000.0


func go_to_next_floor() -> void:
	EventBus.floor_cleared.emit(current_floor)
	current_floor += 1
	call_deferred("_load_floor")


## Run'u bitirir; victory=true zafer, false ölüm.
## GameManager.on_run_ended'i tetikler (meta kayıt oradan yapılır).
func end_run(victory: bool) -> void:
	EventBus.run_ended.emit(victory)


## --- XP & Level (Faz 7) ---

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	EventBus.xp_gained.emit(amount)
	## Level-up döngüsü: tek hamlede birden fazla level atlayabilir.
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = _calc_xp_to_next(level)
		EventBus.player_leveled_up.emit(level)
		## UI upgrade seçim ekranını bu sinyal açar (bkz. upgrade_screen.gd).
		## offer_upgrades() burada çağrılmaz — UI sinyali aldıktan sonra
		## RunManager.offer_upgrades() metodunu kendisi çağırır.


## UI tarafından çağrılır: 3 seçenek hazırla ve döndür.
func offer_upgrades() -> Array[UpgradeData]:
	if upgrade_pool == null:
		return []
	## Daha önce seçilmiş id'leri exclude et (aynı upgrade çift çıkmasın).
	var exclude_ids: Array = selected_upgrades.map(func(u): return u.id)
	_pending_choices = upgrade_pool.roll_choices(_rng, 3, exclude_ids)
	return _pending_choices


## Oyuncu bir upgrade seçince UI bu metodu çağırır.
func confirm_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return
	if stats != null:
		stats.apply_upgrade(upgrade)
	selected_upgrades.append(upgrade)
	_pending_choices.clear()
	EventBus.upgrade_selected.emit(upgrade)


## --- Dahili ---

## Faz 6: her yeni run'da envanter/ekipman/stat'ları sıfırdan kurar (eski
## run'dan kalan child'lar varsa önce temizler).
func _setup_run_state() -> void:
	if inventory != null:
		inventory.queue_free()
	if equipment != null:
		equipment.queue_free()
	if stats != null:
		stats.queue_free()

	inventory = InventoryComponent.new()
	equipment = EquipmentComponent.new()
	stats = StatsComponent.new()

	add_child(inventory)
	add_child(equipment)
	add_child(stats)

	stats.bind_equipment(equipment)
	## Faz 7: yeni run başında upgrade bonusları zaten boş (yeni node),
	## ancak clear_upgrades() ile tutarlı başlangıç garanti edilir.
	stats.clear_upgrades()
	## Meta mağaza: PauseMenu'den kalıcı para ile satın alınmış upgrade'ler
	## her run'da bu yeni StatsComponent'e yeniden uygulanır (kalıcı, run-içi
	## upgrade havuzundan tamamen ayrı bir liste — bkz. GameManager).
	for upgrade in GameManager.get_purchased_meta_upgrades():
		stats.apply_upgrade(upgrade)


func _load_floor() -> void:
	if not is_instance_valid(_floor_parent):
		push_error("RunManager: _floor_parent ayarlanmadı, set_floor_parent() çağrılmalı.")
		return

	## is_instance_valid: ana menüye dönüp (Main sahnesi free olur, eski kat da
	## onunla gider) tekrar başlayınca _current_floor_instance "dangling" olur;
	## düz != null kontrolü free edilmiş node'da queue_free çağırıp çökerdi.
	if is_instance_valid(_current_floor_instance):
		_current_floor_instance.queue_free()
	_current_floor_instance = null

	var floor_instance: Node = DUNGEON_SCENE.instantiate()
	_floor_parent.add_child(floor_instance)
	_current_floor_instance = floor_instance

	var floor_seed := run_seed + current_floor * FLOOR_SEED_STRIDE
	floor_instance.generate(floor_seed)


func _reset_xp() -> void:
	xp = 0
	level = 1
	xp_to_next = _calc_xp_to_next(1)


## XP eğrisi: her level için gereken XP artar.
## level=1→100, level=2→189, level=3→279 ... (base * level^1.5 yaklaşımı)
func _calc_xp_to_next(lvl: int) -> int:
	return int(100 * pow(lvl, 1.5))


func _load_upgrade_pool() -> void:
	if ResourceLoader.exists(UPGRADE_POOL_PATH):
		upgrade_pool = load(UPGRADE_POOL_PATH)
	else:
		push_warning("RunManager: upgrade_pool.tres bulunamadı (%s). " \
				% UPGRADE_POOL_PATH \
				+ "Faz 7 tamamlanınca bu dosyayı oluştur.")


## --- Sinyal alıcılar ---

func _on_enemy_died(enemy: Node, _source: Node) -> void:
	enemies_killed += 1
	## EnemyData.xp_reward değerini düşmandan oku (Faz 5 mimarisi).
	var xp_reward: int = 0
	if enemy.has_method("get") and "data" in enemy and enemy.data is EnemyData:
		xp_reward = enemy.data.xp_reward
	elif enemy.has_meta("xp_reward"):
		xp_reward = enemy.get_meta("xp_reward")
	add_xp(xp_reward)


func _on_player_died() -> void:
	end_run(false)

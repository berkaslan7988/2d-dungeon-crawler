## Juice — Faz 9: ekran-dışı görsel geri bildirim merkezi. Autoload adı: Juice
##
## - hit_stop(): güçlü vuruşta birkaç ms Engine.time_scale düşür (freeze frame).
## - damage_dealt sinyalinde dünya pozisyonunda uçan hasar sayısı + vuruş
##   kıvılcımı spawn eder.
##
## Kamera sarsıntısı BURADA değil, ShakeCamera2D'de işlenir (kameranın kendi
## offset'ini sürdüğü için orada olması daha temiz). Juice sadece zaman + spawn.
extends Node

const DAMAGE_NUMBER: PackedScene = preload("res://scenes/fx/DamageNumber.tscn")
const HIT_SPARK: PackedScene = preload("res://scenes/fx/HitSpark.tscn")

const COLOR_ENEMY_DMG := Color(1.0, 0.96, 0.85)   ## oyuncu→düşman (açık)
const COLOR_PLAYER_DMG := Color(0.95, 0.35, 0.3)  ## düşman→oyuncu (kırmızı)
const COLOR_CRIT := Color(1.0, 0.7, 0.15)         ## kritik (turuncu)

## Faz 11 (opt): damage number havuzu (ön-ısıtmalı, yeniden kullanılır).
const DMG_POOL_SIZE := 24

var _hitstop_token: int = 0
var _dmg_pool: Array[DamageNumber] = []
var _fx_holder: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.hit_stop_requested.connect(hit_stop)
	EventBus.damage_dealt.connect(_on_damage_dealt)

	## Pasif (havuzdaki) damage number'lar burada park eder.
	_fx_holder = Node.new()
	_fx_holder.name = "FXHolder"
	add_child(_fx_holder)
	for i in DMG_POOL_SIZE:
		_dmg_pool.append(_make_dmg())


## Engine.time_scale'i kısa süre düşürür, sonra 1.0'a döndürür.
## Üst üste çağrılırsa yalnızca en son çağrı zamanı 1.0'a döndürür (token).
## Timer ignore_time_scale=true ile gerçek-zaman sayar (yavaşlamadan etkilenmez).
func hit_stop(duration: float, time_scale: float = 0.05) -> void:
	_hitstop_token += 1
	var my_token := _hitstop_token
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if my_token == _hitstop_token:
		Engine.time_scale = 1.0


func _on_damage_dealt(amount: float, world_position: Vector2, to_player: bool, is_crit: bool) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	## Uçan hasar sayısı (havuzdan)
	var dn := _get_dmg()
	if dn.get_parent() != null:
		dn.get_parent().remove_child(dn)
	scene.add_child(dn)
	dn.global_position = world_position + Vector2(0.0, -6.0)
	var col := COLOR_CRIT if is_crit else (COLOR_PLAYER_DMG if to_player else COLOR_ENEMY_DMG)
	dn.popup(amount, is_crit, col)

	## Vuruş kıvılcımı (kısa ömürlü, kendini temizler)
	var spark: Node2D = HIT_SPARK.instantiate()
	scene.add_child(spark)
	spark.global_position = world_position


## --- Damage number havuzu ---

func _make_dmg() -> DamageNumber:
	var dn: DamageNumber = DAMAGE_NUMBER.instantiate()
	dn.hide()
	dn.finished.connect(_reclaim_dmg)
	_fx_holder.add_child(dn)
	return dn


func _get_dmg() -> DamageNumber:
	if _dmg_pool.is_empty():
		return _make_dmg()
	return _dmg_pool.pop_back()


## Animasyon bitince: sahneden çıkar, gizle, havuza geri koy.
func _reclaim_dmg(dn: DamageNumber) -> void:
	dn.hide()
	if dn.get_parent() != null:
		dn.get_parent().remove_child(dn)
	_fx_holder.add_child(dn)
	_dmg_pool.append(dn)

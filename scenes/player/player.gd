## Player — 8 yönlü akıcı hareket, basit yön animasyonu, dash.
## Faz 4: dövüş bileşenleri (Health/Hurtbox/Hitbox) entegre edildi —
## saldırı, i-frame + flash, knockback, ölüm.
## Faz 6: Inventory/Equipment/Stats artık Player üzerinde değil, RunManager
## üzerinde yaşıyor (kat geçişlerinde Player yeniden oluşturulduğu için —
## bkz. run_manager.gd üst yorumu). Player burada sadece RunManager.stats'a
## bağlanıp gerçek Hitbox/Health değerlerini günceller.
## Faz 7: life_steal upgrade efekti _start_attack içinde uygulanır;
## dash_cooldown_multiplier StatsComponent'ten okunur.
extends CharacterBody2D

@export_group("Hareket")
@export var max_speed: float = 90.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0

@export_group("Dash")
@export var dash_speed: float = 260.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.6

@export_group("Dövüş")
@export var attack_cooldown: float = 0.4
@export var attack_active_time: float = 0.12
@export var hitbox_offset: float = 10.0

@export_group("Hasar")
@export var invincible_duration: float = 0.6
@export var knockback_recovery_time: float = 0.18
@export var flash_interval: float = 0.08

var _last_move_dir: Vector2 = Vector2.DOWN
## Faz 8 UX: saldırı yönü artık fare imlecine bakar (hareket yönü yerine).
## AimPivot bu yöne döner; hem görsel ipucu hem gerçek hitbox açısı budur.
var _aim_dir: Vector2 = Vector2.RIGHT
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO

var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _base_knockback: float = 0.0

var _is_invincible: bool = false
var _invincible_timer: float = 0.0
var _flash_timer: float = 0.0

var _is_knocked_back: bool = false
var _knockback_timer: float = 0.0

## Bu run'ın istatistik kaynağı (RunManager.stats ya da standalone fallback).
var _stats: StatsComponent = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var aim_pivot: Node2D = $AimPivot
@onready var slash_effect: Polygon2D = $AimPivot/SlashEffect


func _ready() -> void:
	_base_knockback = hitbox.knockback

	# Normalde RunManager run başında stats'ı kurar. Player.tscn'i tek başına
	# F6 ile çalıştırınca (roadmap mimari ilke #7: her sahne bağımsız test
	# edilebilir olmalı) henüz run başlamamış olur; o durumda yerel bir
	# fallback StatsComponent kurarız ki kod tek bir yoldan ilerlesin.
	_stats = RunManager.stats
	if _stats == null:
		var fallback_equipment := EquipmentComponent.new()
		_stats = StatsComponent.new()
		add_child(fallback_equipment)
		add_child(_stats)
		_stats.bind_equipment(fallback_equipment)

	hurtbox.health_component = health
	hurtbox.stats_component = _stats
	hurtbox.damaged.connect(_on_hurtbox_damaged)
	health.died.connect(_on_died)
	## Faz 7: life_steal — her başarılı vuruşta _apply_life_steal çağrılır.
	hitbox.hit_landed.connect(_apply_life_steal)

	_stats.stats_changed.connect(_on_stats_changed)
	_on_stats_changed()


func _physics_process(delta: float) -> void:
	_update_dash_timers(delta)
	_update_combat_timers(delta)
	_update_invincibility(delta)
	_update_knockback(delta)
	_update_aim()

	if _is_knocked_back:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if Input.is_action_just_pressed("attack") and _can_attack():
		_start_attack()

	if Input.is_action_just_pressed("dash") and _can_dash(input_dir):
		_start_dash(input_dir)

	if _is_dashing:
		velocity = _dash_direction * dash_speed
	elif input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
		_last_move_dir = input_dir
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_update_animation(input_dir)


## Faz 8 UX: AimPivot (ve üzerindeki "silah" göstergesi) sürekli fare
## imlecine döner — saldırı yönü artık nereye baktığınla belirleniyor.
func _update_aim() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		_aim_dir = to_mouse.normalized()
	aim_pivot.rotation = _aim_dir.angle()


func _can_dash(input_dir: Vector2) -> bool:
	return not _is_dashing and _dash_cooldown_timer <= 0.0 and input_dir != Vector2.ZERO


func _start_dash(input_dir: Vector2) -> void:
	_is_dashing = true
	_dash_timer = dash_duration
	## Faz 7: dash_cooldown_multiplier upgrade varsa cooldown'u kısalt.
	var cooldown_mult := _stats.get_dash_cooldown_multiplier() if _stats else 1.0
	_dash_cooldown_timer = dash_cooldown * cooldown_mult
	_dash_direction = input_dir
	## Faz 9: atılma sesi (dosya yoksa AudioManager sessiz geçer).
	EventBus.sfx_requested.emit(&"dash")


func _update_dash_timers(delta: float) -> void:
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta


func _can_attack() -> bool:
	return _attack_cooldown_timer <= 0.0


## Faz 6: hasar/menzil/knockback ve saldırı hızı StatsComponent'ten okunur —
## kuşanılan silah burada gerçek oyun değerlerine yansır.
## Faz 7: hitbox'a _on_hitbox_hit callback'i bağlanır — life_steal hesabı orada.
func _start_attack() -> void:
	var stats := _stats
	hitbox.damage = stats.get_damage()
	hitbox.knockback = _base_knockback + stats.get_knockback_bonus()
	## Faz 8 UX: saldırı yönü artık _aim_dir (fare imleci), eski hareket
	## yönü (_last_move_dir) değil — "saldırı yönünü belli eden görsel ipucu"
	## isteğiyle tutarlı: nereye bakıyorsan oraya vurursun.
	hitbox.position = _aim_dir * (hitbox_offset + stats.get_range_bonus())
	hitbox.activate()
	_play_slash_effect()
	_attack_timer = attack_active_time
	_attack_cooldown_timer = attack_cooldown / max(stats.get_attack_speed(), 0.01)


## Faz 8 UX: "vuruş hissiyatı" — kılıç sallama efektini taklit eden kısa
## bir parlama/ölçek animasyonu. Gerçek bir saldırı animasyonu yerine
## hafif, bağımlılıksız bir "juice" çözümü (sprite sanatı henüz yok).
func _play_slash_effect() -> void:
	slash_effect.visible = true
	slash_effect.scale = Vector2(0.55, 0.55)
	slash_effect.modulate.a = 0.85
	var tween := create_tween()
	tween.tween_property(slash_effect, "scale", Vector2(1.25, 1.25), attack_active_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(slash_effect, "modulate:a", 0.0, attack_active_time)
	tween.finished.connect(func() -> void: slash_effect.visible = false)


## Faz 7: HitboxComponent'in area_entered sinyaline bağlı değil; bunun yerine
## HurtboxComponent'in damaged sinyalini dinleyen şu yaklaşımı kullanıyoruz:
## Hitbox aktifleşince last_dealt_damage'i kaydet, hurtbox_damaged üzerinden life steal uygula.
## Ancak daha temiz yol: _start_attack sonunda direkt çağrılabilecek yardımcı.
func _apply_life_steal(damage_dealt: float) -> void:
	if _stats == null or _stats.life_steal_ratio <= 0.0:
		return
	var heal_amount := damage_dealt * _stats.life_steal_ratio
	health.heal(heal_amount)


func _update_combat_timers(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			hitbox.deactivate()


func _update_invincibility(delta: float) -> void:
	if not _is_invincible:
		return
	_invincible_timer -= delta
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		sprite.visible = not sprite.visible
		_flash_timer = flash_interval
	if _invincible_timer <= 0.0:
		_is_invincible = false
		sprite.visible = true
		hurtbox.set_enabled(true)


func _update_knockback(delta: float) -> void:
	if _knockback_timer <= 0.0:
		return
	_knockback_timer -= delta
	if _knockback_timer <= 0.0:
		_is_knocked_back = false


func _on_hurtbox_damaged(_amount: float, knockback_velocity: Vector2, _source: Node) -> void:
	if _is_invincible:
		return
	velocity = knockback_velocity
	_is_knocked_back = true
	_knockback_timer = knockback_recovery_time
	_is_invincible = true
	_invincible_timer = invincible_duration
	_flash_timer = flash_interval
	hurtbox.set_enabled(false)
	## Faz 9 juice: beyaz flash (i-frame yanıp sönmesine ek anlık vurgu).
	_flash()


## Faz 9: Player.tscn'deki AnimatedSprite2D'ye atanmış flash shader'ı
## kısa süre beyaza çekip geri alır.
func _flash() -> void:
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_amount", 1.0)
	var tw := create_tween()
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.18
	)


## Faz 6: ekipman değişince (StatsComponent.stats_changed) efektif can
## tavanını günceller. Artış varsa (ör. zırh +can bonus) farkı anında
## iyileştirme olarak uygular; azalış varsa mevcut canı yeni tavana kırpar.
func _on_stats_changed() -> void:
	var new_max := _stats.get_max_health()
	var delta := new_max - health.max_health
	health.max_health = new_max
	if delta > 0.0:
		health.heal(delta)
	else:
		health.current_health = min(health.current_health, new_max)


func _on_died() -> void:
	EventBus.player_died.emit()
	set_physics_process(false)
	hurtbox.set_enabled(false)
	hitbox.deactivate()
	sprite.modulate.a = 0.4


func _update_animation(input_dir: Vector2) -> void:
	var moving := input_dir != Vector2.ZERO or _is_dashing
	var dir := _dash_direction if _is_dashing else _last_move_dir

	var anim_prefix := "walk_" if moving else "idle_"
	var anim_suffix := _direction_to_suffix(dir)

	sprite.flip_h = dir.x < 0.0
	sprite.play(anim_prefix + anim_suffix)


func _direction_to_suffix(dir: Vector2) -> String:
	# Yatay hareket dikeyden baskınsa "side" (flip_h ile yön), değilse "up"/"down".
	if absf(dir.x) > absf(dir.y):
		return "side"
	if dir.y < 0.0:
		return "up"
	return "down"

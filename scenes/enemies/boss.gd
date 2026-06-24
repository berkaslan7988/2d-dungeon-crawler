## Boss — Faz 10: son kat boss'u. Çok fazlı, telegraph'lı (önceden belli eden)
## saldırılarla çalışan ayrı bir FSM. Faz 4 bileşenlerini (Health/Hurt/Hitbox)
## yeniden kullanır; ölünce zaferi tetikler (RunManager.end_run(true)).
##
## Saldırı döngüsü: CHASE → (mesafeye göre saldırı seç) → TELEGRAPH (kırmızı
## yanıp şişer, oyuncuya "geliyor" sinyali) → ATTACK (uygula) → RECOVER → CHASE.
## Faz 2 (can ≤ %50): daha hızlı, telegraph kısalır, volley daha yoğun.
extends CharacterBody2D

## DORMANT: oyuncu boss odasına girene kadar bekler (intro diyaloğu için).
enum State { DORMANT, CHASE, TELEGRAPH, ATTACK, RECOVER, DEAD }
enum Attack { SLAM, VOLLEY, SUMMON }

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/Projectile.tscn")
const FLASH_SHADER: Shader = preload("res://assets/shaders/flash.gdshader")
const DEATH_PUFF_SCENE: PackedScene = preload("res://scenes/fx/DeathPuff.tscn")
const SUMMON_DATA: EnemyData = preload("res://data/enemies/mini_slime_data.tres")

## Oyuncu bu mesafeye girince boss "uyanır" ve intro diyaloğu tetiklenir.
const ENCOUNTER_RANGE: float = 130.0

## Faz 10 (hikaye): boss kimliği + diyalogları. DungeonScene add_child'dan
## önce atar. null ise (tek başına test) export varsayılanları kullanılır.
var data: BossData = null

@export var max_health: float = 320.0
@export var move_speed: float = 34.0
@export var slam_damage: float = 22.0
@export var volley_damage: float = 9.0
@export var volley_count: int = 10
@export var summon_count: int = 3
@export var contact_range: float = 26.0

## DungeonScene add_child'dan önce kat zorluk çarpanlarını atar.
var health_scale: float = 1.0
var damage_scale: float = 1.0

var state: State = State.DORMANT
var _attack: Attack = Attack.SLAM
var player: Node2D = null
var phase: int = 1
var _encountered: bool = false   ## intro diyaloğu bir kez tetiklenir

var _timer: float = 0.0          ## mevcut durumun zamanlayıcısı
var _flash_mat: ShaderMaterial = null
var _base_scale: Vector2 = Vector2(2.4, 2.4)
var _tint: Color = Color(0.85, 0.3, 0.35, 1)
var _rng := RandomNumberGenerator.new()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	_rng.randomize()
	add_to_group(Constants.GROUP_ENEMIES)
	_apply_boss_data()

	health.max_health = max_health * health_scale
	health.current_health = health.max_health
	hitbox.damage = slam_damage * damage_scale

	hurtbox.health_component = health
	hurtbox.damaged.connect(_on_hurt)
	health.died.connect(_on_died)

	_setup_flash()
	sprite.scale = _base_scale
	sprite.modulate = _tint

	if player == null:
		player = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)

	## Oyuncu yaklaşana kadar uyur (intro diyaloğu için).
	state = State.DORMANT


## BossData varsa istatistik/görünümü ondan al (yoksa export varsayılanları).
func _apply_boss_data() -> void:
	if data == null:
		return
	max_health = data.max_health
	move_speed = data.move_speed
	slam_damage = data.slam_damage
	volley_damage = data.volley_damage
	volley_count = data.volley_count
	summon_count = data.summon_count
	_base_scale = Vector2.ONE * data.sprite_scale
	_tint = data.sprite_tint


## Oyuncu menzile girince boss uyanır ve intro diyaloğunu tetikler.
func _check_encounter() -> void:
	if _encountered or not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) <= ENCOUNTER_RANGE:
		_encountered = true
		EventBus.boss_encountered.emit(data)
		## Diyalog ekranı oyunu duraklatır; bittiğinde CHASE ile savaş başlar.
		state = State.CHASE
		_timer = 0.8


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if state == State.DORMANT:
		_check_encounter()
		_update_animation()
		return

	_update_phase()
	_update_attack_window(delta)

	match state:
		State.CHASE:
			_state_chase(delta)
		State.TELEGRAPH:
			_state_telegraph(delta)
		State.ATTACK:
			pass  ## saldırı anlıktır, _do_attack içinde RECOVER'a geçer
		State.RECOVER:
			_state_recover(delta)

	move_and_slide()
	_update_animation()


## --- Faz geçişi ---

func _update_phase() -> void:
	if phase == 1 and health.current_health <= health.max_health * 0.5:
		phase = 2
		move_speed *= 1.35
		sprite.modulate = Color(1.0, 0.2, 0.25, 1)
		_flash()  ## faz geçiş vurgusu


## --- Durumlar ---

func _state_chase(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		return
	velocity = (player.global_position - global_position).normalized() * move_speed
	if _timer <= 0.0:
		_choose_attack()
		_enter_telegraph()


func _state_telegraph(delta: float) -> void:
	## Yerinde "şarj" — hafif geri çekilme hissi için yavaşla.
	velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	if _timer <= 0.0:
		_do_attack()


func _state_recover(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 250.0 * delta)
	if _timer <= 0.0:
		state = State.CHASE
		_timer = _rng.randf_range(0.8, 1.6)


func _update_attack_window(delta: float) -> void:
	if _timer > 0.0:
		_timer -= delta
	## Slam hitbox'ı kısa süre açık kalır, sonra kapanır.
	if hitbox.monitoring and state == State.RECOVER:
		pass


## --- Saldırı seçimi & uygulama ---

func _choose_attack() -> void:
	var dist := 9999.0
	if is_instance_valid(player):
		dist = global_position.distance_to(player.global_position)

	var roll := _rng.randf()
	if dist <= 60.0:
		## yakınsa: çoğunlukla slam, bazen summon
		_attack = Attack.SUMMON if roll < 0.25 else Attack.SLAM
	else:
		## uzaksa: volley veya summon
		_attack = Attack.SUMMON if roll < 0.3 else Attack.VOLLEY


func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	## Faz 2'de telegraph kısa (daha zor).
	_timer = 0.5 if phase == 2 else 0.7
	_flash()
	## "Şişme" telegraph: saldırıdan önce büyür.
	var tw := create_tween()
	tw.tween_property(sprite, "scale", _base_scale * 1.18, _timer) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _do_attack() -> void:
	state = State.ATTACK
	## Saldırı sonrası sprite ölçeğini normale döndür.
	create_tween().tween_property(sprite, "scale", _base_scale, 0.15)

	match _attack:
		Attack.SLAM:
			_do_slam()
		Attack.VOLLEY:
			_do_volley()
		Attack.SUMMON:
			_do_summon()

	## Toparlanma süresi (faz 2 daha kısa).
	state = State.RECOVER
	_timer = 0.5 if phase == 2 else 0.8


func _do_slam() -> void:
	var dir := Vector2.DOWN
	if is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	## Oyuncuya doğru atılış + büyük hitbox kısa süre açılır.
	velocity = dir * move_speed * 6.0
	hitbox.position = dir * contact_range
	hitbox.activate()
	## Hitbox'ı kısa süre sonra kapat (callback zincirinde değiliz, timer güvenli).
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		if is_instance_valid(self):
			hitbox.deactivate()
	)
	EventBus.screen_shake_requested.emit(6.0)


func _do_volley() -> void:
	var count := volley_count + (4 if phase == 2 else 0)
	var base_angle := _rng.randf() * TAU
	for i in count:
		var ang := base_angle + TAU * float(i) / float(count)
		var dir := Vector2(cos(ang), sin(ang))
		_spawn_projectile(dir)


func _do_summon() -> void:
	var enemy_scene: PackedScene = load("res://scenes/enemies/Enemy.tscn")
	if enemy_scene == null:
		return
	for i in summon_count:
		var minion: Node2D = enemy_scene.instantiate()
		minion.set("data", SUMMON_DATA)
		minion.set("health_scale", health_scale)
		minion.set("damage_scale", damage_scale)
		minion.set("player", player)
		var off := Vector2(
			_rng.randf_range(-24.0, 24.0),
			_rng.randf_range(-24.0, 24.0)
		)
		minion.position = global_position + off
		get_parent().call_deferred("add_child", minion)


func _spawn_projectile(dir: Vector2) -> void:
	var proj: Node2D = PROJECTILE_SCENE.instantiate()
	proj.position = global_position + dir * 16.0
	if proj.has_method("setup"):
		proj.setup(dir, 80.0, volley_damage * damage_scale)
	get_parent().call_deferred("add_child", proj)


## --- Hasar & ölüm ---

func _on_hurt(_amount: float, _knockback_velocity: Vector2, _source: Node) -> void:
	## Boss knockback'e dirençli (atılmaz), sadece flash.
	if state == State.DEAD:
		return
	_flash()


func _on_died() -> void:
	state = State.DEAD
	## Opt (Faz 11): ölüm sonrası FSM/fizik durur (ölüm tween'i ayrı).
	set_physics_process(false)
	EventBus.enemy_died.emit(self, null)
	## Faz 10 (hikaye): yenilgi diyaloğunu tetikle. Final boss ise DialogueScreen
	## diyalog kapanınca zaferi başlatır; ara boss ise kat "temizlendi" sayılıp
	## (boss queue_free → "enemies" grubu boşalır) çıkış açılır.
	EventBus.boss_defeated.emit(data)
	hurtbox.set_enabled(false)
	hitbox.deactivate()
	call_deferred("set_collision_layer_value", Constants.LAYER_ENEMY, false)

	_spawn_death_puff()

	## Görkemli ölüm.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tw.tween_property(sprite, "scale", _base_scale * 1.6, 0.8) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(queue_free)


func _spawn_death_puff() -> void:
	for i in 5:
		var puff: Node2D = DEATH_PUFF_SCENE.instantiate()
		puff.position = global_position + Vector2(
			_rng.randf_range(-20.0, 20.0), _rng.randf_range(-20.0, 20.0)
		)
		get_parent().call_deferred("add_child", puff)


## --- Görsel yardımcılar ---

func _setup_flash() -> void:
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = FLASH_SHADER
	_flash_mat.set_shader_parameter("flash_amount", 0.0)
	sprite.material = _flash_mat


func _flash() -> void:
	if _flash_mat == null:
		return
	_flash_mat.set_shader_parameter("flash_amount", 1.0)
	var tw := create_tween()
	tw.tween_method(
		func(v: float) -> void: _flash_mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.25
	)


func _update_animation() -> void:
	if sprite.sprite_frames == null:
		return
	var moving := velocity.length() > 4.0
	if moving:
		sprite.flip_h = velocity.x < 0.0
	var anim := "walk" if moving else "idle"
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

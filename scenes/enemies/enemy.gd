## Enemy — basit durum makinesi (FSM) ile çalışan, yeniden kullanılabilir
## düşman. Aynı sahne + farklı bir `EnemyData` = farklı düşman türü.
##
## Pathfinding notu: NavigationRegion2D/NavigationAgent2D yerine roadmap'in
## önerdiği basit yöntem kullanıldı — "oyuncuya doğru düz git + move_and_slide
## duvardan kaysın". Prosedürel kattaki odalar/koridorlar bu küçük ölçekte
## bunun için yeterince geniş; gerçek bir Godot editör oturumu olmadan
## nav-mesh bake akışını güvenilir biçimde doğrulayamadığımdan bu daha
## sağlam seçenek. İhtiyaç olursa NavigationAgent2D'ye sonradan geçilebilir.
extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

const PICKUP_SCENE: PackedScene = preload("res://scenes/items/Pickup.tscn")
## Faz 9 juice
const FLASH_SHADER: Shader = preload("res://assets/shaders/flash.gdshader")
const DEATH_PUFF_SCENE: PackedScene = preload("res://scenes/fx/DeathPuff.tscn")
const DROP_SCATTER_RADIUS: float = 10.0
const FRICTION: float = 600.0
## Takip bırakma menzili detection_range'den büyük tutulur (histerezis) —
## yoksa düşman menzil sınırında CHASE/PATROL arasında çırpınır.
const CHASE_LEASH_MULTIPLIER: float = 1.6
const ATTACK_EXIT_MULTIPLIER: float = 1.2
const HURT_STAGGER_TIME: float = 0.25

@export var data: EnemyData

var state: State = State.IDLE
var player: Node2D = null

var _last_attacker: Node = null
var _spawn_origin: Vector2 = Vector2.ZERO
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_wait_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _hurt_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _flash_mat: ShaderMaterial = null  ## Faz 9: vuruşta beyaz flash

## Faz 10: kat zorluk çarpanları (DungeonScene add_child'dan ÖNCE atar).
var health_scale: float = 1.0
var damage_scale: float = 1.0
## Faz 10: sprite'ın taban ölçeği (data.sprite_scale). Pop/spawn animasyonları
## Vector2.ONE'a değil buna döner — yoksa büyük düşmanlar küçülürdü.
var _base_scale: Vector2 = Vector2.ONE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	_rng.randomize()
	_spawn_origin = global_position
	_pick_new_patrol_target()
	_apply_data()
	_setup_flash()
	_spawn_pop()
	hurtbox.health_component = health
	hurtbox.damaged.connect(_on_hurtbox_damaged)
	health.died.connect(_on_died)
	## BUG FİX: kat geçişinde/retry'da bir frame boyunca eski (silinmek üzere
	## olan) Player ile yeni Player aynı anda "player" grubunda olabiliyor
	## (eski DungeonScene'in queue_free()'si bu frame henüz işlenmedi).
	## get_first_node_in_group bu durumda eskisini döndürebiliyor; o instance
	## frame sonunda silinince is_instance_valid(player) hep false döner ve
	## düşman sonsuza dek IDLE'da kalıp asla saldırmaz. DungeonScene artık
	## kendi player referansını doğrudan veriyor (bkz. _spawn_enemies) — grup
	## araması sadece sahne tek başına test edilirse (data atanmadıysa) devreye
	## girer.
	if player == null:
		player = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)


func _apply_data() -> void:
	if data == null:
		push_warning("Enemy: 'data' (EnemyData) atanmadı, varsayılan değerler kullanılacak.")
		return
	## Faz 10: kat zorluk çarpanı uygulanır. current_health'i de elle eşitle —
	## HealthComponent._ready max_health'i (Enemy.tscn varsayılanı) kullanıp
	## current'ı oradan kurmuştu; yeni max'a göre yenilemezsek can yanlış olur.
	health.max_health = data.max_health * health_scale
	health.current_health = health.max_health
	if data.sprite_frames != null:
		sprite.sprite_frames = data.sprite_frames
	_base_scale = Vector2.ONE * data.sprite_scale
	sprite.scale = _base_scale
	sprite.modulate = data.sprite_tint
	hitbox.damage = data.damage * damage_scale
	hitbox.knockback = data.knockback


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_update_timers(delta)

	match state:
		State.IDLE:
			_state_idle()
		State.PATROL:
			_state_patrol(delta)
		State.CHASE:
			_state_chase()
		State.ATTACK:
			_state_attack(delta)
		State.HURT:
			_state_hurt(delta)

	move_and_slide()
	_update_animation()


func _update_timers(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			hitbox.deactivate()
	if state == State.PATROL and _patrol_wait_timer > 0.0:
		_patrol_wait_timer -= delta


func _state_idle() -> void:
	if _can_see_player():
		_change_state(State.CHASE)
		return
	_change_state(State.PATROL)


func _state_patrol(delta: float) -> void:
	if _can_see_player():
		_change_state(State.CHASE)
		return

	if _patrol_wait_timer > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		return

	var to_target := _patrol_target - global_position
	if to_target.length() <= 2.0:
		_patrol_wait_timer = data.patrol_wait_time if data else 1.5
		_pick_new_patrol_target()
		velocity = Vector2.ZERO
		return

	velocity = to_target.normalized() * _move_speed() * 0.5


func _state_chase() -> void:
	if not is_instance_valid(player):
		_change_state(State.IDLE)
		return

	var dist := global_position.distance_to(player.global_position)
	var detection := _detection_range()
	if dist > detection * CHASE_LEASH_MULTIPLIER:
		_change_state(State.PATROL)
		return

	var attack_range := _attack_range()
	if dist <= attack_range:
		_change_state(State.ATTACK)
		return

	velocity = (player.global_position - global_position).normalized() * _move_speed()


func _state_attack(delta: float) -> void:
	if not is_instance_valid(player):
		_change_state(State.IDLE)
		return

	var dist := global_position.distance_to(player.global_position)

	## Faz 10 (kiting): menzilli düşman oyuncu fazla yaklaşınca geri çekilir;
	## yoksa yerinde durur. Yakın dövüşçü her zaman yerinde durur.
	var flee := data.flee_distance if data else 0.0
	if flee > 0.0 and dist < flee:
		velocity = (global_position - player.global_position).normalized() * _move_speed()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	if dist > _attack_range() * ATTACK_EXIT_MULTIPLIER:
		_change_state(State.CHASE)
		return

	if _attack_cooldown_timer <= 0.0 and _attack_timer <= 0.0:
		_start_attack()


func _state_hurt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	_hurt_timer -= delta
	if _hurt_timer <= 0.0:
		_change_state(State.CHASE if is_instance_valid(player) else State.IDLE)


func _start_attack() -> void:
	var dir := Vector2.DOWN
	if is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()

	## Faz 10: menzilli düşman mermi atar, yakın dövüşçü hitbox açar.
	if data != null and data.attack_type == EnemyData.AttackType.RANGED:
		_fire_projectile(dir)
	else:
		hitbox.position = dir * _attack_range()
		hitbox.activate()

	_attack_timer = data.attack_active_time if data else 0.15
	_attack_cooldown_timer = data.attack_cooldown if data else 1.0


## Faz 10: data.projectile_scene'den bir mermi üretip oyuncuya doğru fırlatır.
func _fire_projectile(dir: Vector2) -> void:
	if data.projectile_scene == null:
		push_warning("Enemy (%s): RANGED ama projectile_scene atanmadı." % [data.display_name])
		return
	var proj: Node2D = data.projectile_scene.instantiate()
	proj.position = global_position + dir * 8.0
	if proj.has_method("setup"):
		proj.setup(dir, data.projectile_speed, data.damage * damage_scale)
	## Fizik callback'i içinde olmasak da tutarlılık için deferred ekliyoruz.
	get_parent().call_deferred("add_child", proj)


func _change_state(new_state: State) -> void:
	state = new_state


func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= _detection_range()


func _move_speed() -> float:
	return data.move_speed if data else 40.0


func _detection_range() -> float:
	return data.detection_range if data else 70.0


func _attack_range() -> float:
	return data.attack_range if data else 14.0


func _pick_new_patrol_target() -> void:
	var radius := data.patrol_radius if data else 40.0
	var angle := randf() * TAU
	var dist := randf() * radius
	_patrol_target = _spawn_origin + Vector2(cos(angle), sin(angle)) * dist


func _on_hurtbox_damaged(_amount: float, knockback_velocity: Vector2, source: Node) -> void:
	if state == State.DEAD:
		return
	_last_attacker = source
	velocity = knockback_velocity
	_hurt_timer = HURT_STAGGER_TIME
	hitbox.deactivate()
	_change_state(State.HURT)
	## Faz 9 juice: beyaz flash + "squash" pop.
	_flash()
	_pop()


## --- Faz 9 juice yardımcıları ---

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
		1.0, 0.0, 0.18
	)


func _pop() -> void:
	sprite.scale = Vector2(_base_scale.x * 1.3, _base_scale.y * 0.75)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", _base_scale, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_pop() -> void:
	sprite.scale = _base_scale * 0.2
	var tw := create_tween()
	tw.tween_property(sprite, "scale", _base_scale, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## `died` sinyali bir Area2D çarpışma callback'i (area_entered) zinciri
## içinden gelir; fizik durumunu değiştiren her şey deferred yapılır
## ("flushing queries" hatasını önlemek için, Faz 4'te öğrenilen ders).
func _on_died() -> void:
	_change_state(State.DEAD)
	## Opt (Faz 11): ölü düşman artık FSM/fizik işletmesin (ölüm tween'i ayrı çalışır).
	set_physics_process(false)
	EventBus.enemy_died.emit(self, _last_attacker)
	_drop_loot()
	_spawn_death_puff()
	_spawn_splits()
	hurtbox.set_enabled(false)
	call_deferred("set_collision_layer_value", 4, false)
	hitbox.deactivate()
	## Faz 9: küçük "şişip sönme" + saydamlaşarak kaybolma.
	var death_tween := create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	death_tween.tween_property(sprite, "scale", _base_scale * 1.4, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	death_tween.chain().tween_callback(queue_free)


## Faz 9: ölüm partikülü. Loot ile aynı desen — fizik callback zincirinde
## doğrudan add_child "flushing queries" hatası verir, bu yüzden deferred.
func _spawn_death_puff() -> void:
	var puff: Node2D = DEATH_PUFF_SCENE.instantiate()
	puff.position = global_position
	get_parent().call_deferred("add_child", puff)


## Faz 10: bölünme — ölünce data.split_into türünden split_count adet spawn.
## Sonsuz bölünmeyi önlemek için mini'nin EnemyData'sında split_count=0 olmalı.
## preload yerine load(): enemy.gd, Enemy.tscn'in script'i; kendi sahnesini
## preload etmek döngüsel bağımlılık riski taşır, runtime load güvenli.
func _spawn_splits() -> void:
	if data == null or data.split_into == null or data.split_count <= 0:
		return
	var enemy_scene: PackedScene = load("res://scenes/enemies/Enemy.tscn")
	if enemy_scene == null:
		return
	for i in data.split_count:
		var minion: Node2D = enemy_scene.instantiate()
		minion.set("data", data.split_into)
		minion.set("health_scale", health_scale)
		minion.set("damage_scale", damage_scale)
		minion.set("player", player)
		var off := Vector2(
			_rng.randf_range(-10.0, 10.0),
			_rng.randf_range(-10.0, 10.0)
		)
		minion.position = global_position + off
		get_parent().call_deferred("add_child", minion)


## Faz 6: EnemyData'daki LootTable'a göre yere eşya saçar (Pickup).
func _drop_loot() -> void:
	if data == null or data.loot_table == null:
		return
	for item in data.loot_table.roll(_rng):
		var pickup: Pickup = PICKUP_SCENE.instantiate()
		pickup.item = item
		var offset := Vector2(
			_rng.randf_range(-DROP_SCATTER_RADIUS, DROP_SCATTER_RADIUS),
			_rng.randf_range(-DROP_SCATTER_RADIUS, DROP_SCATTER_RADIUS)
		)
		pickup.position = global_position + offset
		## call_deferred: fizik callback zinciri içinde Area2D eklemek
		## "flushing queries" hatasına yol açar — ekleme bir sonraki frame'e ertelenir.
		get_parent().call_deferred("add_child", pickup)


func _update_animation() -> void:
	if sprite.sprite_frames == null:
		return
	var moving := velocity.length() > 2.0
	if moving:
		sprite.flip_h = velocity.x < 0.0
	var anim := "walk" if moving else "idle"
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

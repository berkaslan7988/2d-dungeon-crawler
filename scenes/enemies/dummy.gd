## Dummy — Faz 4 dövüş sistemini test etmek için basit, hareketsiz "kukla".
## AI yok; sadece Health/Hurtbox bileşenlerini gerçek bir varlık üzerinde
## doğrulamaya yarar. Faz 5'te gerçek Enemy.tscn + FSM ile değiştirilecek.
extends CharacterBody2D

var _last_attacker: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent


func _ready() -> void:
	hurtbox.health_component = health
	hurtbox.damaged.connect(_on_hurtbox_damaged)
	health.died.connect(_on_died)


func _on_hurtbox_damaged(_amount: float, _knockback_velocity: Vector2, source: Node) -> void:
	_last_attacker = source
	sprite.modulate = Color(1.0, 0.4, 0.4)
	var flash_tween := create_tween()
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


## `died` sinyali, bir Area2D çarpışma callback'i (area_entered) zinciri
## içinden gelir; bu yüzden fizik durumunu değiştiren her şey (monitoring,
## collision layer) deferred yapılır — "flushing queries" hatasını önler.
func _on_died() -> void:
	EventBus.enemy_died.emit(self, _last_attacker)
	hurtbox.set_enabled(false)
	call_deferred("set_collision_layer_value", 4, false)
	var death_tween := create_tween()
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	death_tween.tween_callback(queue_free)

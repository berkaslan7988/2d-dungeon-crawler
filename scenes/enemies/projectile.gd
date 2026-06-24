## Projectile — Faz 10: menzilli düşmanların attığı mermi.
## Kök Area2D hareketi + duvar çarpışmasını + ömrü yönetir; çocuk
## HitboxComponent ise hasarı MEVCUT hitbox→hurtbox boru hattından geçirir
## (böylece damage number, knockback, kamera sarsıntısı otomatik gelir).
##
## Katmanlar: kök layer=projectiles(9), mask=world(1) → duvara değince yok olur.
## Hitbox layer=enemy_hitbox(7), mask=player_hurtbox(3) → sadece oyuncuya vurur
## (düşmanlara ve atan düşmana değmez; self-collision yok).
class_name Projectile
extends Area2D

@export var speed: float = 90.0
@export var damage: float = 8.0
@export var lifetime: float = 3.0

var _dir: Vector2 = Vector2.RIGHT

@onready var hitbox: HitboxComponent = $HitboxComponent


## enemy.gd add_child'dan ÖNCE çağırır (değerleri saklar; _ready kullanır).
func setup(dir: Vector2, spd: float, dmg: float) -> void:
	_dir = dir.normalized() if dir.length() > 0.0 else Vector2.RIGHT
	speed = spd
	damage = dmg


func _ready() -> void:
	rotation = _dir.angle()
	hitbox.damage = damage
	hitbox.activate()
	hitbox.hit_landed.connect(_on_hit_landed)
	body_entered.connect(_on_body_entered)
	## Ömür dolunca yok ol (erken yok olmuşsa guard ile çökme önlenir).
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			queue_free()
	)


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta


## Duvara (world layer) değince yok ol.
func _on_body_entered(_body: Node) -> void:
	queue_free()


## Oyuncuya isabet edince yok ol (hasar zaten hurtbox tarafında uygulandı).
func _on_hit_landed(_dmg: float) -> void:
	queue_free()

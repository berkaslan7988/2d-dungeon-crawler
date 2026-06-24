## HitboxComponent — hasar veren alan. Saldıran varlık bunu kısa süre
## aktif eder (activate/deactivate); bir HurtboxComponent'e değdiğinde
## kendi `damage`/`knockback` değerlerini taşır.
## Aynı aktivasyonda bir hedefe birden fazla vurmamak için `_hit_targets`
## listesi tutulur (çift hasar engeli).
##
## activate()/deactivate() bazen bir çarpışma sinyali (örn. ölüm zinciri)
## içinden çağrılabilir; bu yüzden monitoring/monitorable/shape.disabled
## hep set_deferred ile değiştirilir (fizik motoru "flushing queries"
## hatası vermesin diye).
class_name HitboxComponent
extends Area2D

## Faz 7: bir hurtbox'a başarıyla vurulunca tetiklenir (life_steal için).
## Parametre: gerçekte uygulanıp uygulanmadığından bağımsız ham hasar değeri.
signal hit_landed(damage: float)

@export var damage: float = 10.0
@export var knockback: float = 120.0

var _hit_targets: Array = []


func _ready() -> void:
	monitoring = false
	monitorable = false
	_set_shapes_disabled(true)


## Saldırı başladığında çağrılır: alanı açar, vurulanlar listesini sıfırlar.
func activate() -> void:
	_hit_targets.clear()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	_set_shapes_disabled(false)


## Saldırı bittiğinde çağrılır: alanı kapatır.
func deactivate() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	_set_shapes_disabled(true)


func can_hit(target: HurtboxComponent) -> bool:
	return not _hit_targets.has(target)


func register_hit(target: HurtboxComponent) -> void:
	_hit_targets.append(target)
	## Faz 7: bu hitbox'a bağlı life_steal gibi efektler için sinyal yay.
	hit_landed.emit(damage)


func _set_shapes_disabled(disabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", disabled)

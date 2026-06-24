## HealthComponent — can/ölüm mantığını taşıyan, yeniden kullanılabilir Node.
## Hem oyuncu hem düşmanlar aynı bileşeni kullanır.
class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0

var current_health: float = 0.0


func _ready() -> void:
	current_health = max_health


func is_dead() -> bool:
	return current_health <= 0.0


func take_damage(amount: float) -> void:
	if is_dead():
		return
	current_health = max(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health == 0.0:
		died.emit()


func heal(amount: float) -> void:
	if is_dead():
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

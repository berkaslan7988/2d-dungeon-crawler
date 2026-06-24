## HurtboxComponent — hasar alabilen alan. Bir HitboxComponent kendisine
## değdiğinde bağlı HealthComponent'e hasar yazar ve `damaged` sinyalini
## yayar (knockback yönü dahil). Sahip varlık (Player/Enemy) bu sinyale
## bağlanıp knockback/i-frame/flash gibi tepkileri kendi mantığıyla uygular —
## bu sayede bileşen, sahibinin iç detaylarını bilmek zorunda kalmaz.
##
## Faz 6: `stats_component` atanmışsa (şimdilik sadece Player), gelen ham
## hasar StatsComponent.apply_defense() ile savunmaya göre azaltılır.
## Enemy'lerde bu alan boş bırakılır — düşmanlar zırh takmıyor, ham hasarı
## doğrudan alırlar.
class_name HurtboxComponent
extends Area2D

signal damaged(amount: float, knockback_velocity: Vector2, source: Node)

@export var health_component: HealthComponent
@export var stats_component: StatsComponent


func _ready() -> void:
	area_entered.connect(_on_area_entered)


## `damaged` sinyali her zaman bir Area2D çarpışma callback'i (area_entered)
## içinden tetiklenir; bu yüzden monitoring'i kapatıp açmak isteyen çağıranlar
## doğrudan `monitoring = ...` yazmak yerine bunu kullanmalı — set_deferred,
## fizik motoru sorgularını "flush" ederken patlamayı önler.
func set_enabled(enabled: bool) -> void:
	set_deferred("monitoring", enabled)


## Not: `area is HitboxComponent` denetimi GDScript'in statik tip
## çıkarımını otomatik daraltmaz (TypeScript'teki gibi narrowing yok) —
## bu yüzden `area`yı doğrudan kullanmak "Cannot infer type" parser
## hatasına yol açar. Tek bir `as HitboxComponent` cast'iyle tipli bir
## yerel değişkene alıp onun üzerinden devam ediyoruz.
func _on_area_entered(area: Area2D) -> void:
	if not (area is HitboxComponent):
		return

	var hitbox := area as HitboxComponent

	if health_component == null or health_component.is_dead():
		return
	if not hitbox.can_hit(self):
		return

	hitbox.register_hit(self)

	var final_damage: float = hitbox.damage
	if stats_component != null:
		final_damage = StatsComponent.apply_defense(hitbox.damage, stats_component.get_defense())

	health_component.take_damage(final_damage)

	var dir := (global_position - hitbox.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	damaged.emit(final_damage, dir * hitbox.knockback, hitbox.get_parent())

	## Faz 9 juice: global geri bildirim (hasar sayısı, kıvılcım, kamera
	## sarsıntısı; güçlü vuruşlarda kısa hit-stop). to_player: hasarı alan
	## taraf oyuncu mu? (kırmızı sayı / daha güçlü sarsıntı için).
	var parent := get_parent()
	var to_player: bool = parent != null and parent.is_in_group(Constants.GROUP_PLAYER)
	EventBus.damage_dealt.emit(final_damage, global_position, to_player, false)
	EventBus.screen_shake_requested.emit(clampf(2.0 + final_damage * 0.15, 2.0, 7.0))
	if final_damage >= 12.0:
		EventBus.hit_stop_requested.emit(0.05, 0.06)

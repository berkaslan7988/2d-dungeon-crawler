## DamageNumber — Faz 9: vuruşta uçup kaybolan hasar sayısı.
## Faz 11 (opt): artık queue_free yerine `finished` sinyali yayar ve Juice
## tarafından havuza geri alınıp yeniden kullanılır (instance churn'ü azalır).
class_name DamageNumber
extends Node2D

## Animasyon bitince Juice bunu dinleyip node'u havuza geri koyar.
signal finished(node: DamageNumber)

@onready var label: Label = $Label

var _tween: Tween = null


## Juice çağırır: instance/pool'dan al → global_position ayarla → popup().
func popup(amount: float, is_crit: bool, color: Color) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	visible = true
	modulate.a = 1.0
	label.text = str(int(round(amount))) + ("!" if is_crit else "")
	label.modulate = color
	label.add_theme_font_size_override("font_size", 14 if is_crit else 9)
	scale = Vector2.ONE * (1.35 if is_crit else 1.0)

	var start_pos := position
	var rise := -16.0 - randf() * 8.0
	var drift := randf_range(-7.0, 7.0)

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", start_pos + Vector2(drift, rise), 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN).set_delay(0.1)
	_tween.chain().tween_callback(func() -> void: finished.emit(self))

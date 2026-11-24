## PixelBar — a crisp, banded bar: dark outline, track, fill with a light top
## row and a shaded bottom row, optional segment ticks. When the value drops,
## the lost part flashes parchment and drains away (the "chip").
class_name PixelBar
extends Control

var fill := UIKit.FLAME
var fill_light := UIKit.GOLD_LT
var fill_mid := UIKit.GOLD
var fill_shade := UIKit.EMBER
var track := UIKit.SLATE_2
var outline := UIKit.VOID
## Number of segments drawn with ticks (0 = none).
var segments: int = 0

var _value: float = 1.0
var _max: float = 1.0
var _chip: float = 0.0
var _chip_tween: Tween


static func make(w: int, h: int, style: String = "ember") -> PixelBar:
	var b := PixelBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match style:
		"bone":
			b.fill = UIKit.BONE
			b.fill_light = UIKit.PARCH
			b.fill_mid = UIKit.BONE
			b.fill_shade = UIKit.ASH_LT
			b.track = UIKit.SLATE_1
		"blood":
			b.fill = UIKit.BLOOD
			b.fill_light = UIKit.ROSE
			b.fill_mid = UIKit.BLOOD
			b.fill_shade = UIKit.BLOOD_DK
	return b


func set_values(value: float, maximum: float) -> void:
	var old_ratio := _ratio()
	_max = maxf(maximum, 0.001)
	_value = clampf(value, 0.0, _max)
	var new_ratio := _ratio()
	if new_ratio < old_ratio:
		_chip = maxf(_chip, old_ratio)
		if _chip_tween != null and _chip_tween.is_valid():
			_chip_tween.kill()
		_chip_tween = create_tween()
		_chip_tween.tween_interval(0.25)
		_chip_tween.tween_method(func(v: float) -> void:
			_chip = v
			queue_redraw(), _chip, new_ratio, 0.35)
	else:
		_chip = new_ratio
	queue_redraw()


func _ratio() -> float:
	return clampf(_value / _max, 0.0, 1.0)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).abs()
	draw_rect(r, outline)
	var inner := r.grow(-1)
	draw_rect(inner, track)
	var chip_w := floorf(inner.size.x * _chip)
	var w := floorf(inner.size.x * _ratio())
	if chip_w > w:
		draw_rect(Rect2(inner.position + Vector2(w, 0), Vector2(chip_w - w, inner.size.y)), UIKit.PARCH)
	if w > 0:
		var f := Rect2(inner.position, Vector2(w, inner.size.y))
		draw_rect(f, fill)
		draw_rect(Rect2(f.position, Vector2(w, 1)), fill_light)
		if inner.size.y >= 5:
			draw_rect(Rect2(f.position + Vector2(0, 1), Vector2(w, 1)), fill_mid)
		if inner.size.y >= 3:
			draw_rect(Rect2(f.position + Vector2(0, f.size.y - 1), Vector2(w, 1)), fill_shade)
	if segments > 1:
		for i in range(1, segments):
			var x := inner.position.x + floorf(inner.size.x * i / segments)
			draw_rect(Rect2(x, inner.position.y, 1, inner.size.y), Color(outline, 0.6))

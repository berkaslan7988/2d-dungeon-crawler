## ShakeCamera2D — Faz 9: EventBus.screen_shake_requested geldiğinde noise
## tabanlı, şiddeti azalan bir kamera sarsıntısı uygular. Player'ın Camera2D'sine
## eklenir; Player her kat yeniden oluştuğunda sinyale yeniden bağlanır.
##
## Roadmap notu: şiddet sınırlı tutulur (max_offset) — abartılı sarsıntı
## oyuncuyu rahatsız eder. İleride Ayarlar'dan kısılabilir (shake_scale).
extends Camera2D

@export var decay: float = 8.0          ## sönme hızı (büyük = hızlı durur)
@export var max_offset: float = 7.0      ## azami sarsıntı (piksel)
@export var shake_scale: float = 1.0     ## genel çarpan (Ayarlar için)

var _strength: float = 0.0
var _noise := FastNoiseLite.new()
var _t: float = 0.0


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.5
	EventBus.screen_shake_requested.connect(add_shake)


func add_shake(amount: float) -> void:
	_strength = minf(_strength + amount * shake_scale, max_offset)


func _process(delta: float) -> void:
	if _strength <= 0.0:
		return
	_strength = lerpf(_strength, 0.0, decay * delta)
	_t += delta * 30.0
	offset = Vector2(
		_noise.get_noise_2d(_t, 0.0),
		_noise.get_noise_2d(0.0, _t)
	) * _strength
	if _strength < 0.05:
		_strength = 0.0
		offset = Vector2.ZERO

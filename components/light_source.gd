## LightSource — anything that gives off light: the player's flame, braziers,
## the stairs, frost orbs, a Warden's crown. LightManager collects every node
## in the "sc_light" group each frame and hands them to the shaders.
class_name LightSource
extends Node2D

const GROUP: StringName = &"sc_light"

## Reach in world pixels.
@export var radius: float = 96.0
## Light level at the centre (the tile shader clamps the sum to 5).
@export var intensity: float = 3.0
## How much the intensity wavers, like a flame.
@export var flicker: float = 0.0
@export var enabled: bool = true
## Only shines once its tile has been seen (braziers, the stairs).
@export var fog_gated: bool = false

var _t: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	_t = randf() * 100.0


func _process(delta: float) -> void:
	_t += delta


func current_intensity() -> float:
	if flicker <= 0.0:
		return intensity
	var wave := sin(_t * 11.0) * 0.5 + sin(_t * 6.7 + 1.3) * 0.35 + sin(_t * 23.0) * 0.15
	return intensity + wave * flicker

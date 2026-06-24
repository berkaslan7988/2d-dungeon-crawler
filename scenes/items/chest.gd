## Chest — Faz 10 (kullanıcı isteği): oyuncu YAKLAŞINCA otomatik açılır,
## oyunu durdurup içindekileri bir ekranda gösterir (ChestScreen) ve eşyalar
## doğrudan envantere eklenir. Artık yere pickup saçmıyor / tuşa basmıyoruz.
class_name Chest
extends StaticBody2D

const MIN_ROLLS: int = 2
const MAX_ROLLS: int = 3
## Bazı sandıklardan run-içi yetenek kartı da çıkar (level-up havuzundan).
const UPGRADE_CHANCE: float = 0.4

@export var loot_table: LootTable

var _opened: bool = false
var _rng := RandomNumberGenerator.new()

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_zone: Area2D = $InteractZone


func _ready() -> void:
	_rng.randomize()
	interact_zone.body_entered.connect(_on_zone_body_entered)


## Oyuncu yaklaşma alanına girince (tek seferlik) açılır.
func _on_zone_body_entered(body: Node) -> void:
	if _opened:
		return
	if body.is_in_group(Constants.GROUP_PLAYER):
		_open()


func _open() -> void:
	_opened = true
	sprite.modulate = Color(0.6, 0.55, 0.5)
	EventBus.sfx_requested.emit(&"chest")

	## Eşyaları topla (birkaç bağımsız roll → "dolu sandık" hissi).
	var items: Array = []
	if loot_table != null:
		var roll_count := _rng.randi_range(MIN_ROLLS, MAX_ROLLS)
		for i in roll_count:
			for item in loot_table.roll(_rng):
				items.append(item)

	## Şansa bağlı bir yetenek kartı (bu run'da seçilmemişlerden).
	var upgrade: UpgradeData = null
	if RunManager.upgrade_pool != null and _rng.randf() < UPGRADE_CHANCE:
		var exclude: Array = RunManager.selected_upgrades.map(func(u): return u.id)
		var choices := RunManager.upgrade_pool.roll_choices(_rng, 1, exclude)
		if not choices.is_empty():
			upgrade = choices[0]

	## ChestScreen oyunu durdurup içeriği gösterir ve envantere ekler.
	EventBus.chest_opened.emit(items, upgrade)

## Pickup — yerde duran, oyuncu üstüne gelince envantere giren eşya.
## Görseli runtime'da `item.icon`'dan alınır; tek sahne her ItemData için
## yeniden kullanılır (ayrı bir .tscn gerekmez).
class_name Pickup
extends Area2D

@export var item: ItemData
@export var count: int = 1

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if item != null and item.icon != null:
		sprite.texture = item.icon


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(Constants.GROUP_PLAYER):
		return
	if item == null or RunManager.inventory == null:
		return

	var leftover := RunManager.inventory.add_item(item, count)
	EventBus.item_picked_up.emit(item)

	if leftover <= 0:
		queue_free()
	else:
		# Envanter dolu — sığmayan kısmı yerde bırak, sığanı düşür.
		count = leftover

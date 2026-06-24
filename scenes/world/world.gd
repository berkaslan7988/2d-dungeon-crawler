## World — Faz 2: elle yapılmış test odası.
## Prosedürel üretimden (Faz 3) önce TileMapLayer + çarpışmayı doğrulamak için
## sabit, dikdörtgen bir oda çiziyor: kenarlar duvar, içi zemin.
extends Node2D

const ROOM_WIDTH: int = 14
const ROOM_HEIGHT: int = 10

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(1, 0)
const TILESET_SOURCE_ID: int = 0

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer


func _ready() -> void:
	_build_test_room()


func _build_test_room() -> void:
	for y in range(ROOM_HEIGHT):
		for x in range(ROOM_WIDTH):
			var cell := Vector2i(x, y)
			var is_border := x == 0 or y == 0 or x == ROOM_WIDTH - 1 or y == ROOM_HEIGHT - 1
			if is_border:
				wall_layer.set_cell(cell, TILESET_SOURCE_ID, WALL_ATLAS_COORDS)
			else:
				floor_layer.set_cell(cell, TILESET_SOURCE_ID, FLOOR_ATLAS_COORDS)

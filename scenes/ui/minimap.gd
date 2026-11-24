## Minimap — bottom right. Draws only what the flame has revealed (the same
## explored mask the light shader uses, LightManager), the stairs once seen,
## and the player.
extends Control

const CELL_PX: int = 2
const COLOR_FLOOR := Color("303347")
const COLOR_EXIT := Color("ec7a2a")
const COLOR_PLAYER := Color("ffe39a")
const COLOR_BG := Color(0.0235, 0.0235, 0.0353, 0.88)
const COLOR_BORDER := Color("303347")

var _grid_w: int = 0
var _grid_h: int = 0
var _grid: Array = []
var _player_grid_pos: Vector2i = Vector2i(-1, -1)
var _exit_grid_pos: Vector2i = Vector2i(-1, -1)
var _floor_layer: TileMapLayer = null
var _player_node: Node2D = null
var _exit_marker: Node2D = null


func _ready() -> void:
	EventBus.run_started.connect(func() -> void: call_deferred("_find_dungeon_refs"))
	EventBus.floor_cleared.connect(func(_n: int) -> void: call_deferred("_find_dungeon_refs"))
	LightManager.explored_changed.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _find_dungeon_refs() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var dungeon: Node = get_tree().get_first_node_in_group("dungeon_scene")
	if dungeon == null:
		return
	_floor_layer = dungeon.get_node_or_null("FloorLayer")
	_exit_marker = dungeon.get_node_or_null("Markers/ExitMarker")
	var gen = dungeon.get("generator")
	if gen != null:
		_grid = gen.grid
		_grid_w = gen.width
		_grid_h = gen.height
		custom_minimum_size = Vector2(_grid_w * CELL_PX + 4, _grid_h * CELL_PX + 4)
		size = custom_minimum_size
	_player_node = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
	queue_redraw()


func _process(_delta: float) -> void:
	if _player_node == null or not is_instance_valid(_player_node):
		_player_node = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
	if _player_node != null and _floor_layer != null:
		var p := _world_to_grid(_player_node.global_position)
		if p != _player_grid_pos:
			_player_grid_pos = p
			queue_redraw()
	if _exit_marker != null and _floor_layer != null:
		_exit_grid_pos = _world_to_grid(_exit_marker.global_position)


func _draw() -> void:
	if _grid.is_empty():
		return
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, COLOR_BG)
	draw_rect(r, COLOR_BORDER, false, 1.0)
	var o := Vector2(2, 2)
	for y in _grid_h:
		for x in _grid_w:
			if _grid[y][x] == 1 and LightManager.is_explored(Vector2i(x, y)):
				draw_rect(Rect2(o + Vector2(x, y) * CELL_PX, Vector2.ONE * CELL_PX), COLOR_FLOOR)
	if _exit_grid_pos != Vector2i(-1, -1) and LightManager.is_explored(_exit_grid_pos):
		draw_rect(Rect2(o + Vector2(_exit_grid_pos) * CELL_PX - Vector2.ONE, Vector2.ONE * (CELL_PX + 2)), COLOR_EXIT)
	if _player_grid_pos != Vector2i(-1, -1):
		draw_rect(Rect2(o + Vector2(_player_grid_pos) * CELL_PX - Vector2.ONE, Vector2.ONE * (CELL_PX + 2)), COLOR_PLAYER)


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	if _floor_layer == null:
		return Vector2i(-1, -1)
	return _floor_layer.local_to_map(_floor_layer.to_local(world_pos))

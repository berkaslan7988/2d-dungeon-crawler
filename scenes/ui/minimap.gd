## Minimap — sağ alt köşede küçük harita göstergesi.
## DungeonGenerator'ın grid verisini okur, _draw() ile çizer.
## Oyuncu pozisyonu ve çıkış noktası anlık güncellenir.
## Her kat yüklenince refresh_map() çağrılarak yenilenir.
##
## Faz 8 UX düzeltmesi: roadmap "keşfedilen oda/koridorları gösteren küçük
## harita" istiyor — önceki sürüm tüm grid'i baştan çiziyordu (sis yoktu).
## Artık oyuncunun etrafındaki hücreler _visited grid'inde işaretlenir ve
## sadece o hücreler çizilir (basit "fog of war").
extends Control

## Her grid hücresi bu kadar piksel olarak çizilir (minimap ölçeği).
const CELL_PX: int = 2

## Oyuncunun her an etrafında keşfettiği yarıçap (grid hücresi cinsinden).
const REVEAL_RADIUS: int = 5

const COLOR_FLOOR   := Color("3a3a4a")
const COLOR_WALL    := Color(0, 0, 0, 0)       ## duvarlar çizilmez (boşluk)
const COLOR_PLAYER  := Color("2ecc71")          ## yeşil nokta
const COLOR_EXIT    := Color("f1c40f")          ## sarı nokta
const COLOR_BG      := Color(0.05, 0.05, 0.08, 0.85)
const COLOR_BORDER  := Color("555577")

## Minimap boyutu (grid'e göre dinamik ayarlanır _update_size() ile).
var _grid_w: int = 0
var _grid_h: int = 0
var _grid: Array = []

## _visited[y][x] == true ise o hücre daha önce keşfedilmiş (çizilir).
## Yeni kat yüklenince (_find_dungeon_refs) sıfırdan kurulur — her katın
## kendi sisi olur.
var _visited: Array = []

## Dünya pozisyonunu grid koordinatına çevirmek için referanslar.
## Bunlar DungeonScene'den her kat yüklenince set edilir.
var _player_grid_pos: Vector2i = Vector2i(-1, -1)
var _exit_grid_pos:   Vector2i = Vector2i(-1, -1)
var _floor_layer: TileMapLayer = null
var _player_node: Node2D = null
var _exit_marker: Node2D = null


func _ready() -> void:
	## Sinyal bağlantıları: kat yüklenince ve run başlayınca yenile.
	EventBus.run_started.connect(_on_run_started)
	EventBus.floor_cleared.connect(_on_floor_cleared)
	set_process(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_run_started() -> void:
	call_deferred("_find_dungeon_refs")


func _on_floor_cleared(_n: int) -> void:
	call_deferred("_find_dungeon_refs")


## DungeonScene'deki referansları bulur ve minimap'i yeniler.
## call_deferred ile çağrılır — _load_floor bir frame geciktirir.
func _find_dungeon_refs() -> void:
	## Birkaç frame bekle: DungeonScene add_child call_deferred ile eklendi.
	await get_tree().process_frame
	await get_tree().process_frame

	## DungeonScene'i bul (FloorRoot'un çocuğu).
	var dungeon: Node = null
	for child in get_tree().get_nodes_in_group("dungeon_scene"):
		dungeon = child
		break
	## Grup yoksa sahne ağacında ara.
	if dungeon == null:
		var floor_root := get_tree().root.find_child("FloorRoot", true, false)
		if floor_root and floor_root.get_child_count() > 0:
			dungeon = floor_root.get_child(0)

	if dungeon == null:
		return

	_floor_layer = dungeon.get_node_or_null("FloorLayer")
	_exit_marker = dungeon.get_node_or_null("Markers/ExitMarker")

	## Grid verisini al (DungeonGenerator public).
	var gen = dungeon.get("generator")
	if gen != null:
		_grid   = gen.grid
		_grid_w = gen.width
		_grid_h = gen.height
		_update_size()
		_reset_fog()

	_player_node = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
	queue_redraw()


func _process(_delta: float) -> void:
	if _player_node == null or not is_instance_valid(_player_node):
		_player_node = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)

	var dirty := false
	if _player_node != null and _floor_layer != null:
		var new_pos := _world_to_grid(_player_node.global_position)
		if new_pos != _player_grid_pos:
			_player_grid_pos = new_pos
			dirty = true
		if _reveal_around(_player_grid_pos):
			dirty = true

	if _exit_marker != null and _floor_layer != null:
		var new_ep := _world_to_grid(_exit_marker.global_position)
		if new_ep != _exit_grid_pos:
			_exit_grid_pos = new_ep
			dirty = true

	if dirty:
		queue_redraw()


func _draw() -> void:
	if _grid.is_empty():
		return

	## Arka plan
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BORDER, false, 1.0)

	## Grid hücreleri — sadece keşfedilmiş (_visited) hücreler çizilir.
	for y in _grid_h:
		for x in _grid_w:
			if _grid[y][x] == 1 and _is_visited(x, y):   ## FLOOR + keşfedildi
				var rect := Rect2(x * CELL_PX, y * CELL_PX, CELL_PX, CELL_PX)
				draw_rect(rect, COLOR_FLOOR)

	## Çıkış (sarı nokta, 3px) — sadece o hücre keşfedildiyse gösterilir.
	if _exit_grid_pos != Vector2i(-1, -1) and _is_visited(_exit_grid_pos.x, _exit_grid_pos.y):
		var ep := Vector2(_exit_grid_pos) * CELL_PX + Vector2.ONE * CELL_PX * 0.5
		draw_circle(ep, CELL_PX * 1.5, COLOR_EXIT)

	## Oyuncu (yeşil nokta, 3px)
	if _player_grid_pos != Vector2i(-1, -1):
		var pp := Vector2(_player_grid_pos) * CELL_PX + Vector2.ONE * CELL_PX * 0.5
		draw_circle(pp, CELL_PX * 1.5, COLOR_PLAYER)


func _update_size() -> void:
	custom_minimum_size = Vector2(_grid_w * CELL_PX, _grid_h * CELL_PX)
	size = custom_minimum_size


## Yeni kat: tüm sis geri çöker (bilinmeyen hücreler tekrar gizlenir).
func _reset_fog() -> void:
	_visited.clear()
	for _y in _grid_h:
		var row: Array = []
		row.resize(_grid_w)
		row.fill(false)
		_visited.append(row)


func _is_visited(x: int, y: int) -> bool:
	if y < 0 or y >= _visited.size():
		return false
	if x < 0 or x >= _visited[y].size():
		return false
	return _visited[y][x]


## center_cell etrafındaki REVEAL_RADIUS yarıçapındaki hücreleri keşfedilmiş
## olarak işaretler. Herhangi bir hücre yeni işaretlendiyse true döner
## (yalnızca o zaman queue_redraw çağırmaya değer).
func _reveal_around(center_cell: Vector2i) -> bool:
	if _visited.is_empty() or center_cell == Vector2i(-1, -1):
		return false

	var changed := false
	var r := REVEAL_RADIUS
	for y in range(max(center_cell.y - r, 0), min(center_cell.y + r + 1, _grid_h)):
		for x in range(max(center_cell.x - r, 0), min(center_cell.x + r + 1, _grid_w)):
			if Vector2(x - center_cell.x, y - center_cell.y).length() <= r and not _visited[y][x]:
				_visited[y][x] = true
				changed = true
	return changed


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	if _floor_layer == null:
		return Vector2i(-1, -1)
	return _floor_layer.local_to_map(_floor_layer.to_local(world_pos))

## DungeonGenerator — basit "oda + koridor" prosedürel zindan üretici.
## Çıktı: 2D grid (Array of Array[int]) — 0=boş, 1=zemin, 2=duvar.
## Aynı seed → aynı zindan (debug & paylaşım için).
class_name DungeonGenerator
extends RefCounted

const EMPTY: int = 0
const FLOOR: int = 1
const WALL: int = 2

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]

var width: int = 0
var height: int = 0
var grid: Array = []          # grid[y][x]
var rooms: Array[Rect2i] = []

var rng := RandomNumberGenerator.new()


func generate(
	w: int,
	h: int,
	seed_value: int,
	max_rooms: int = 12,
	room_min: int = 5,
	room_max: int = 11
) -> Array:
	width = w
	height = h
	rng.seed = seed_value
	_init_grid()
	rooms.clear()

	for i in max_rooms:
		var rw := rng.randi_range(room_min, room_max)
		var rh := rng.randi_range(room_min, room_max)
		var rx := rng.randi_range(1, width - rw - 1)
		var ry := rng.randi_range(1, height - rh - 1)
		var new_room := Rect2i(rx, ry, rw, rh)

		var overlaps := false
		for r in rooms:
			if new_room.grow(1).intersects(r):
				overlaps = true
				break
		if overlaps:
			continue

		_carve_room(new_room)
		if rooms.size() > 0:
			_connect(rooms[-1].get_center(), new_room.get_center())
		rooms.append(new_room)

	return grid


## Tüm zemin hücreleri tek bir bağlı bölge mi? (Faz 3'ün kritik garantisi.)
func is_fully_connected() -> bool:
	var start := _find_first_floor()
	if start == Vector2i(-1, -1):
		return false
	return _flood_fill(start).size() == _count_floor()


## `start` hücresinden tüm ulaşılabilir zemin hücrelerine BFS mesafesi.
## Çıkışı/spawn noktalarını "en uzak oda" mantığıyla yerleştirmek için kullanılır.
func bfs_distances(start: Vector2i) -> Dictionary:
	var visited := {start: 0}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for dir in DIRECTIONS:
			var n: Vector2i = current + dir
			if _is_floor(n) and not visited.has(n):
				visited[n] = visited[current] + 1
				queue.append(n)
	return visited


func _init_grid() -> void:
	grid = []
	for y in height:
		var row: Array = []
		for x in width:
			row.append(WALL)
		grid.append(row)


func _carve_room(r: Rect2i) -> void:
	for y in range(r.position.y, r.position.y + r.size.y):
		for x in range(r.position.x, r.position.x + r.size.x):
			grid[y][x] = FLOOR


func _connect(a: Vector2i, b: Vector2i) -> void:
	if rng.randf() < 0.5:
		_h_tunnel(a.x, b.x, a.y)
		_v_tunnel(a.y, b.y, b.x)
	else:
		_v_tunnel(a.y, b.y, a.x)
		_h_tunnel(a.x, b.x, b.y)


func _h_tunnel(x1: int, x2: int, y: int) -> void:
	for x in range(min(x1, x2), max(x1, x2) + 1):
		grid[y][x] = FLOOR


func _v_tunnel(y1: int, y2: int, x: int) -> void:
	for y in range(min(y1, y2), max(y1, y2) + 1):
		grid[y][x] = FLOOR


func _is_floor(p: Vector2i) -> bool:
	if p.x < 0 or p.y < 0 or p.x >= width or p.y >= height:
		return false
	return grid[p.y][p.x] == FLOOR


func _find_first_floor() -> Vector2i:
	for y in height:
		for x in width:
			if grid[y][x] == FLOOR:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _count_floor() -> int:
	var count := 0
	for y in height:
		for x in width:
			if grid[y][x] == FLOOR:
				count += 1
	return count


func _flood_fill(start: Vector2i) -> Dictionary:
	var visited := {}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if visited.has(c):
			continue
		visited[c] = true
		for dir in DIRECTIONS:
			var n: Vector2i = c + dir
			if _is_floor(n) and not visited.has(n):
				stack.append(n)
	return visited

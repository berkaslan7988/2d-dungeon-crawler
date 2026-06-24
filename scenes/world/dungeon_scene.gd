## DungeonScene — Faz 3: prosedürel olarak üretilmiş, gezilebilir bir kat.
## DungeonGenerator'dan gelen grid'i TileMapLayer'lara döşer, bağlanabilirliği
## doğrular (gerekirse yeniden üretir), oyuncuyu başlangıca koyar, çıkışı
## başlangıçtan en uzak odaya yerleştirir ve diğer odalara debug spawn
## marker'ları koyar.
## Faz 5: o marker'lara EnemyData havuzundan seçilen gerçek Enemy.tscn
## (FSM'li) örnekleri spawn ediliyor.
## Faz 6: ayrıca bir oda içine, açılınca loot saçan bir Chest yerleştiriliyor.
extends Node2D

const GRID_WIDTH: int = 48
const GRID_HEIGHT: int = 32
const MAX_ROOMS: int = 12
const ROOM_MIN: int = 5
const ROOM_MAX: int = 9
const MAX_GENERATION_ATTEMPTS: int = 20

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(1, 0)
const TILESET_SOURCE_ID: int = 0

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/Enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/Boss.tscn")

## Faz 10 (hikaye): bu katlarda normal düşman yerine ilgili boss çıkar.
## Kat 9 (Vorlak) final — yenilince zafer; 3 ve 6 yenilince kat açılır.
var _boss_floors: Dictionary = {
	3: preload("res://data/bosses/warden1_garoth.tres"),
	6: preload("res://data/bosses/warden2_myrra.tres"),
	9: preload("res://data/bosses/warden3_vorlak.tres"),
}

## Faz 10: ağırlıklı, kat-kapılı (min_floor) düşman havuzu. Erken katlarda
## sadece slime/yarasa; ilerledikçe bölünen/okçu/tank devreye girer.
var _enemy_specs: Array = [
	{"data": preload("res://data/enemies/slime_data.tres"),    "min_floor": 1, "weight": 10.0},
	{"data": preload("res://data/enemies/bat_data.tres"),      "min_floor": 1, "weight": 7.0},
	{"data": preload("res://data/enemies/splitter_data.tres"), "min_floor": 2, "weight": 5.0},
	{"data": preload("res://data/enemies/archer_data.tres"),   "min_floor": 2, "weight": 5.0},
	{"data": preload("res://data/enemies/brute_data.tres"),    "min_floor": 3, "weight": 4.0},
]

const CHEST_SCENE: PackedScene = preload("res://scenes/items/Chest.tscn")
const CHEST_LOOT_TABLE: LootTable = preload("res://data/loot_tables/common_chest_loot_table.tres")
const CHEST_OFFSET := Vector2(10.0, 0.0)

const DIAGONAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]

var generator := DungeonGenerator.new()
var _spawned_enemies: Array = []
var _spawned_chest: Node = null

## Özellik 1: çıkış, kat temizlenene (tüm düşmanlar ölene) kadar kapalı.
var _floor_cleared: bool = false
var _had_enemies: bool = false
## Final boss katında çıkış ilerletmez — zafer diyalog sonrası gelir.
var _is_final_boss_floor: bool = false
## Opt (Faz 11): temizlik kontrolünü her karede değil ~0.3 sn'de bir yap.
var _clear_check_accum: float = 0.0

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var entities: Node2D = $Entities
@onready var markers: Node2D = $Markers
@onready var player: Node2D = $Entities/Player
@onready var exit_marker: Area2D = $Markers/ExitMarker


func _ready() -> void:
	## Faz 8: Minimap bu grubu kullanarak aktif DungeonScene'i bulur.
	add_to_group("dungeon_scene")
	exit_marker.body_entered.connect(_on_exit_marker_body_entered)


func generate(seed_value: int) -> void:
	_generate_valid_grid(seed_value)
	_paint_grid()
	_place_player()
	_place_exit()
	_place_spawn_markers()
	_spawn_enemies()
	_spawn_chest()
	_setup_clear_gate()


## Özellik 1: kat düşmanla doluysa çıkış (henüz) ilerletmez. Çıkış Area2D'si
## hep aktif; ilerlemeyi _floor_cleared bayrağı denetler.
func _setup_clear_gate() -> void:
	_floor_cleared = false
	_had_enemies = _spawned_enemies.size() > 0
	if not _had_enemies:
		_open_exit(false)


## Her karede sahnede canlı düşman kalmadıysa katı "temizlendi" say. Dinamik
## spawn (bölünme/boss çağırma) da "enemies" grubunda olduğu için onlar ölene
## kadar kat temizlenmiş sayılmaz.
func _process(delta: float) -> void:
	if _floor_cleared:
		return
	## Her karede grup sorgusu yerine ~0.3 sn'de bir kontrol et.
	_clear_check_accum += delta
	if _clear_check_accum < 0.3:
		return
	_clear_check_accum = 0.0
	var alive := get_tree().get_nodes_in_group(Constants.GROUP_ENEMIES)
	if not alive.is_empty():
		_had_enemies = true
	elif _had_enemies:
		_open_exit(true)


func _open_exit(announce: bool) -> void:
	_floor_cleared = true
	if announce:
		EventBus.hud_toast.emit("Kat temizlendi — çıkışa ilerle!")
	## Boss çıkışın üstünde durduğundan, oyuncu temizlenince zaten çıkışta
	## olabilir (body_entered tetiklenmez). Bu durumu elle yakala.
	if not _is_final_boss_floor:
		for body in exit_marker.get_overlapping_bodies():
			if body.is_in_group(Constants.GROUP_PLAYER):
				RunManager.go_to_next_floor()
				return


func _generate_valid_grid(seed_value: int) -> void:
	var attempt_seed := seed_value
	for attempt in MAX_GENERATION_ATTEMPTS:
		generator.generate(GRID_WIDTH, GRID_HEIGHT, attempt_seed, MAX_ROOMS, ROOM_MIN, ROOM_MAX)
		if generator.is_fully_connected() and generator.rooms.size() >= 2:
			return
		attempt_seed += 1
		push_warning(
			"DungeonScene: zindan bağlı değil/yetersiz oda, yeniden üretiliyor (seed=%d)"
			% attempt_seed
		)


func _paint_grid() -> void:
	floor_layer.clear()
	wall_layer.clear()
	for y in generator.height:
		for x in generator.width:
			var cell := Vector2i(x, y)
			match generator.grid[y][x]:
				DungeonGenerator.FLOOR:
					floor_layer.set_cell(cell, TILESET_SOURCE_ID, FLOOR_ATLAS_COORDS)
				DungeonGenerator.WALL:
					if _touches_floor(cell):
						wall_layer.set_cell(cell, TILESET_SOURCE_ID, WALL_ATLAS_COORDS)


## Sadece zemine değen duvarları döşe; haritanın görünmeyen iç kısımlarını
## (asla zemine değmeyen duvar hücrelerini) boş bırak — gereksiz tile yok.
func _touches_floor(cell: Vector2i) -> bool:
	for dir in DIAGONAL_DIRECTIONS:
		var n := cell + dir
		if n.x < 0 or n.y < 0 or n.x >= generator.width or n.y >= generator.height:
			continue
		if generator.grid[n.y][n.x] == DungeonGenerator.FLOOR:
			return true
	return false


func _place_player() -> void:
	var start_room: Rect2i = generator.rooms[0]
	player.global_position = _cell_to_world(start_room.get_center())


func _place_exit() -> void:
	var start_room: Rect2i = generator.rooms[0]
	var distances := generator.bfs_distances(start_room.get_center())

	var farthest_room: Rect2i = generator.rooms[0]
	var farthest_distance := -1
	for room in generator.rooms:
		var center: Vector2i = room.get_center()
		if distances.has(center) and distances[center] > farthest_distance:
			farthest_distance = distances[center]
			farthest_room = room

	exit_marker.global_position = _cell_to_world(farthest_room.get_center())


func _place_spawn_markers() -> void:
	for child in markers.get_children():
		if child != exit_marker:
			child.queue_free()

	for i in range(1, generator.rooms.size()):
		var room: Rect2i = generator.rooms[i]
		var marker := Marker2D.new()
		marker.name = "EnemySpawn_%d" % i
		marker.global_position = _cell_to_world(room.get_center())
		markers.add_child(marker)


## Faz 10: Boss katıysa boss spawn'la (normal düşman yok). Aksi halde her
## odaya kat zorluğuna göre ölçeklenmiş, ağırlıklı seçilmiş düşmanlar koyar.
func _spawn_enemies() -> void:
	for enemy in _spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned_enemies.clear()

	var floor_num: int = RunManager.current_floor

	if _boss_floors.has(floor_num):
		_spawn_boss(floor_num, _boss_floors[floor_num])
		return

	var hp_scale := _health_scale(floor_num)
	var dmg_scale := _damage_scale(floor_num)
	## Faz 10: kat ilerledikçe oda başına düşman sayısı artar (1→4 arası).
	## Tam sayı bölme kasıtlı (kat 1-2→1, 3-4→2 ...).
	@warning_ignore("integer_division")
	var per_room: int = clampi(1 + floor_num / 2, 1, 4)

	for child in markers.get_children():
		if not child.name.begins_with("EnemySpawn_"):
			continue
		for i in per_room:
			var enemy: Node = ENEMY_SCENE.instantiate()
			## Faz 3 not: global randi() yerine generator'ın seed'lenmiş rng'si.
			enemy.data = _pick_enemy_data(floor_num)
			## Faz 10: kat zorluk çarpanları (add_child'dan ÖNCE atanmalı —
			## _ready içindeki _apply_data bunları okur).
			enemy.health_scale = hp_scale
			enemy.damage_scale = dmg_scale
			## ÖNEMLİ: pozisyon add_child'dan ÖNCE (patrol origin _ready'de okunur).
			var scatter := Vector2(
				generator.rng.randf_range(-14.0, 14.0),
				generator.rng.randf_range(-14.0, 14.0)
			) if i > 0 else Vector2.ZERO
			enemy.global_position = child.global_position + scatter
			## Player referansını doğrudan ver (grup araması kat geçişinde kırılgan).
			enemy.player = player
			entities.add_child(enemy)
			_spawned_enemies.append(enemy)


## Faz 10: boss'u başlangıçtan en uzak odaya (çıkış odası) koyar. Çıkış zaten
## kat-temizleme kapısıyla kapalı; boss ölünce (grup boşalınca) açılır — ara
## boss'larda ilerleme, final boss'ta ise diyalog sonrası zafer.
func _spawn_boss(floor_num: int, boss_data: BossData) -> void:
	_is_final_boss_floor = boss_data.is_final
	var boss: Node = BOSS_SCENE.instantiate()
	boss.data = boss_data
	boss.health_scale = _health_scale(floor_num)
	boss.damage_scale = _damage_scale(floor_num)
	boss.global_position = exit_marker.global_position
	boss.player = player
	entities.add_child(boss)
	_spawned_enemies.append(boss)


## Faz 10: kat-kapılı ağırlıklı düşman türü seçimi (deterministik rng).
func _pick_enemy_data(floor_num: int) -> EnemyData:
	var total := 0.0
	for spec in _enemy_specs:
		if floor_num >= spec["min_floor"]:
			total += spec["weight"]
	if total <= 0.0:
		return _enemy_specs[0]["data"]

	var pick := generator.rng.randf() * total
	var acc := 0.0
	for spec in _enemy_specs:
		if floor_num < spec["min_floor"]:
			continue
		acc += spec["weight"]
		if pick <= acc:
			return spec["data"]
	return _enemy_specs[0]["data"]


## Faz 10 zorluk eğrisi (roadmap formülü): her kat +%15 can, +%10 hasar.
func _health_scale(floor_num: int) -> float:
	return 1.0 + (floor_num - 1) * 0.15


func _damage_scale(floor_num: int) -> float:
	return 1.0 + (floor_num - 1) * 0.10


## Faz 6: başlangıç dışındaki ilk odaya, açılınca loot saçan bir Chest koyar.
func _spawn_chest() -> void:
	if _spawned_chest != null and is_instance_valid(_spawned_chest):
		_spawned_chest.queue_free()
	_spawned_chest = null

	if generator.rooms.size() < 2:
		return

	var room: Rect2i = generator.rooms[1]
	var chest: Node = CHEST_SCENE.instantiate()
	chest.loot_table = CHEST_LOOT_TABLE
	entities.add_child(chest)
	chest.global_position = _cell_to_world(room.get_center()) + CHEST_OFFSET
	_spawned_chest = chest


func _cell_to_world(cell: Vector2i) -> Vector2:
	return floor_layer.to_global(floor_layer.map_to_local(cell))


func _on_exit_marker_body_entered(body: Node) -> void:
	if not body.is_in_group(Constants.GROUP_PLAYER):
		return
	## Özellik 1: kat temizlenmeden geçiş yok.
	if not _floor_cleared:
		EventBus.hud_toast.emit("Önce tüm düşmanları temizle!")
		return
	## Final boss katı: ilerleme yok; zafer, boss yenilgi diyaloğu sonrası gelir.
	if _is_final_boss_floor:
		return
	RunManager.go_to_next_floor()

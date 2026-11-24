## LightManager — feeds the light model. Autoload name: LightManager
##
## Each frame it packs the nearest LightSources into a 16×1 float texture
## (x, y, radius, intensity) that the tile and sprite shaders read as the
## global uniform `sc_lights`. It also keeps the floor's explored mask
## (`sc_fog`): tiles the flame has reached stay faintly visible, the rest of
## the floor is black. The minimap reads the same mask.
extends Node

signal explored_changed

const MAX_LIGHTS: int = 16
const TILE: int = 16
## Tiles within this radius of the player count as seen.
const REVEAL_RADIUS: float = 9.0
const REVEAL_INTERVAL: float = 0.1

var _light_img: Image
var _light_tex: ImageTexture
var _fog_img: Image
var _fog_tex: ImageTexture
var _fog_size := Vector2i(1, 1)
var _fog_origin := Vector2.ZERO
var _fog_active := false
var _fog_dirty := false
var _reveal_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_light_img = Image.create(MAX_LIGHTS, 1, false, Image.FORMAT_RGBAF)
	_light_tex = ImageTexture.create_from_image(_light_img)
	RenderingServer.global_shader_parameter_set(&"sc_lights", _light_tex)
	RenderingServer.global_shader_parameter_set(&"sc_light_count", 0)
	clear_fog()


func _process(delta: float) -> void:
	_pack_lights()
	if _fog_active:
		_reveal_timer -= delta
		if _reveal_timer <= 0.0:
			_reveal_timer = REVEAL_INTERVAL
			var player := get_tree().get_first_node_in_group(Constants.GROUP_PLAYER) as Node2D
			if player != null:
				reveal(player.global_position, REVEAL_RADIUS)
	if _fog_dirty:
		_fog_dirty = false
		_fog_tex.update(_fog_img)
		explored_changed.emit()


func _pack_lights() -> void:
	var nodes := get_tree().get_nodes_in_group(LightSource.GROUP)
	var centre := Vector2.ZERO
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		centre = cam.get_screen_center_position()
	var lights: Array = []
	for n in nodes:
		var ls := n as LightSource
		if ls == null or not ls.enabled or not ls.is_visible_in_tree():
			continue
		if ls.fog_gated and not is_explored_world(ls.global_position):
			continue
		lights.append(ls)
	if lights.size() > MAX_LIGHTS:
		lights.sort_custom(func(a, b) -> bool:
			return a.global_position.distance_squared_to(centre) < b.global_position.distance_squared_to(centre))
	var count := mini(lights.size(), MAX_LIGHTS)
	for i in count:
		var ls: LightSource = lights[i]
		var p := ls.global_position
		_light_img.set_pixel(i, 0, Color(p.x, p.y, ls.radius, ls.current_intensity()))
	_light_tex.update(_light_img)
	RenderingServer.global_shader_parameter_set(&"sc_light_count", count)


## --- Explored mask -----------------------------------------------------------

## Menus and test rooms: everything counts as seen.
func clear_fog() -> void:
	_fog_active = false
	_fog_size = Vector2i(1, 1)
	_fog_img = Image.create(1, 1, false, Image.FORMAT_R8)
	_fog_img.fill(Color.WHITE)
	_fog_tex = ImageTexture.create_from_image(_fog_img)
	RenderingServer.global_shader_parameter_set(&"sc_fog", _fog_tex)
	RenderingServer.global_shader_parameter_set(&"sc_fog_rect", Vector4(-1e6, -1e6, 2e6, 2e6))
	explored_changed.emit()


## A new floor: grid size in tiles and the world position of tile (0, 0)'s
## top-left corner. Everything starts unseen.
func setup_fog(size: Vector2i, origin: Vector2) -> void:
	_fog_active = true
	_fog_size = size
	_fog_origin = origin
	_fog_img = Image.create(size.x, size.y, false, Image.FORMAT_R8)
	_fog_img.fill(Color.BLACK)
	_fog_tex = ImageTexture.create_from_image(_fog_img)
	RenderingServer.global_shader_parameter_set(&"sc_fog", _fog_tex)
	RenderingServer.global_shader_parameter_set(&"sc_fog_rect",
			Vector4(origin.x, origin.y, size.x * TILE, size.y * TILE))
	_reveal_timer = 0.0
	explored_changed.emit()


func reveal(world_pos: Vector2, radius_tiles: float) -> void:
	if not _fog_active:
		return
	var c := Vector2i(((world_pos - _fog_origin) / TILE).floor())
	var r := int(ceil(radius_tiles))
	for y in range(maxi(c.y - r, 0), mini(c.y + r + 1, _fog_size.y)):
		for x in range(maxi(c.x - r, 0), mini(c.x + r + 1, _fog_size.x)):
			if Vector2(x - c.x, y - c.y).length() <= radius_tiles and _fog_img.get_pixel(x, y).r < 0.5:
				_fog_img.set_pixel(x, y, Color.WHITE)
				_fog_dirty = true


func is_explored_world(world_pos: Vector2) -> bool:
	return is_explored(Vector2i(((world_pos - _fog_origin) / TILE).floor()))


func is_explored(cell: Vector2i) -> bool:
	if not _fog_active:
		return true
	if cell.x < 0 or cell.y < 0 or cell.x >= _fog_size.x or cell.y >= _fog_size.y:
		return false
	return _fog_img.get_pixel(cell.x, cell.y).r > 0.5

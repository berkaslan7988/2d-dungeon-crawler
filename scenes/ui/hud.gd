## HUD — always-on information over the dungeon.
## Top left: life (an ember bar, segmented every 10), experience and level,
## the weapon in hand. Top right: floor tracker (nine pips, Warden floors as
## red diamonds) and souls. Bottom left: dash. Bottom centre: a Warden's
## name and health while one is awake. Updates are signal driven.
##
## The Player is rebuilt on every floor, so its health is re-bound on
## run_started and floor_cleared.
extends CanvasLayer

const K = preload("res://scenes/ui/ui_kit.gd")
const FLOORS: int = 9
const WARDEN_FLOORS: Array[int] = [3, 6, 9]

var _health_component: HealthComponent = null
var _toast_tween: Tween = null
var _player: Node = null
var _boss_health: HealthComponent = null

var _life_bar: PixelBar
var _life_now: Label
var _life_max: Label
var _xp_bar: PixelBar
var _lv: Label
var _weapon_icon: TextureRect
var _weapon_name: Label
var _weapon_stats: Label
var _floor_num: Label
var _pips: FloorPips
var _souls: Label
var _toast: Label
var _dash_bar: PixelBar
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: PixelBar


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in get_children():
		c.queue_free()
	_build()

	EventBus.xp_gained.connect(func(_a: int) -> void: _refresh_xp())
	EventBus.player_leveled_up.connect(func(_l: int) -> void: _refresh_xp())
	EventBus.floor_cleared.connect(_on_floor_cleared)
	EventBus.meta_currency_changed.connect(func(t: int) -> void: _souls.text = str(t))
	EventBus.run_started.connect(_on_run_started)
	EventBus.player_died.connect(func() -> void: _life_bar.set_values(0, 1))
	EventBus.upgrade_selected.connect(func(u: UpgradeData) -> void:
		_show_toast("+ " + u.get_name_text(), K.boon_color(u.rarity)))
	EventBus.hud_toast.connect(func(t: String) -> void: _show_toast(t, K.PARCH))
	EventBus.boss_encountered.connect(_on_boss_encountered)
	EventBus.boss_defeated.connect(func(_d: BossData) -> void: _boss_box.visible = false)
	Settings.changed.connect(_refresh_texts)

	_refresh_floor()
	_refresh_xp()
	_souls.text = str(GameManager.meta_currency)
	if RunManager.stats != null:
		_on_run_started()


# --- layout ------------------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.name = "Control"
	add_child(root)

	# top left
	var tl := K.vbox(4)
	tl.position = Vector2(10, 9)
	root.add_child(tl)
	var life_row := K.hbox(5)
	life_row.add_child(K.icon(K.EMBER_ICON))
	_life_bar = PixelBar.make(110, 10, "ember")
	_life_bar.segments = 10
	_life_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	life_row.add_child(_life_bar)
	var life_lbl := K.hbox(0)
	_life_now = K.shadowed(K.num("100", 14, K.PARCH))
	_life_max = K.shadowed(K.num(" / 100", 14, K.ASH_LT))
	life_lbl.add_child(_life_now)
	life_lbl.add_child(_life_max)
	life_row.add_child(life_lbl)
	tl.add_child(life_row)

	var xp_row := K.hbox(5)
	var xp_pad := Control.new()
	xp_pad.custom_minimum_size = Vector2(6, 0)
	xp_row.add_child(xp_pad)
	_xp_bar = PixelBar.make(110, 6, "bone")
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_row.add_child(_xp_bar)
	_lv = K.shadowed(K.num("LV 1", 11, K.BONE))
	xp_row.add_child(_lv)
	tl.add_child(xp_row)

	var w_row := K.hbox(6)
	var w_pad := Control.new()
	w_pad.custom_minimum_size = Vector2(5, 0)
	w_row.add_child(w_pad)
	var slot := K.panel(1, K.SLATE_3, K.SOOT)
	slot.custom_minimum_size = Vector2(20, 20)
	_weapon_icon = K.icon(null)
	_weapon_icon.custom_minimum_size = Vector2(16, 16)
	slot.add_child(_weapon_icon)
	w_row.add_child(slot)
	var w_text := K.vbox(0)
	_weapon_name = K.shadowed(K.label("", 9, K.PARCH, K.font_medium()))
	_weapon_stats = K.shadowed(K.num("", 10, K.ASH_LT))
	w_text.add_child(_weapon_name)
	w_text.add_child(_weapon_stats)
	w_row.add_child(w_text)
	tl.add_child(w_row)

	# top right
	var tr_box := K.vbox(4)
	tr_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tr_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr_box.offset_right = -10
	tr_box.offset_top = 7
	tr_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(tr_box)
	var floor_row := K.hbox(3)
	floor_row.alignment = BoxContainer.ALIGNMENT_END
	floor_row.add_child(K.shadowed(K.num(tr("HUD_FLOOR"), 11, K.ASH_LT)))
	_floor_num = K.shadowed(K.num("1", 20, K.PARCH))
	floor_row.add_child(_floor_num)
	floor_row.add_child(K.shadowed(K.num("/ %d" % FLOORS, 11, K.ASH_LT)))
	for c in floor_row.get_children():
		c.size_flags_vertical = Control.SIZE_SHRINK_END
	floor_row.name = "FloorRow"
	tr_box.add_child(floor_row)
	_pips = FloorPips.new()
	_pips.size_flags_horizontal = Control.SIZE_SHRINK_END
	tr_box.add_child(_pips)
	var souls_row := K.hbox(4)
	souls_row.alignment = BoxContainer.ALIGNMENT_END
	var soul_icon := K.icon(K.SOUL_ICON)
	soul_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	souls_row.add_child(soul_icon)
	_souls = K.shadowed(K.num("0", 17, K.GOLD))
	souls_row.add_child(_souls)
	tr_box.add_child(souls_row)

	# bottom left: dash
	var dash := K.hbox(4)
	dash.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	dash.offset_left = 10
	dash.offset_top = -20
	dash.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dash.add_child(K.key_cap("SHIFT"))
	var dash_lbl := K.shadowed(K.num(tr("HUD_DASH"), 11, K.ASH_LT))
	dash_lbl.name = "DashLabel"
	dash.add_child(dash_lbl)
	_dash_bar = PixelBar.make(22, 5, "bone")
	_dash_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dash.add_child(_dash_bar)
	dash.name = "Dash"
	root.add_child(dash)

	# toast
	_toast = K.shadowed(K.label("", 11, K.PARCH, K.font_medium()))
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 56
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	# Warden bar
	_boss_box = K.vbox(2)
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.offset_top = -50
	_boss_box.offset_bottom = -12
	_boss_box.offset_left = -150
	_boss_box.offset_right = 150
	_boss_box.alignment = BoxContainer.ALIGNMENT_END
	_boss_name = K.title("", 22)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	_boss_bar = PixelBar.make(300, 8, "blood")
	_boss_box.add_child(_boss_bar)
	_boss_box.visible = false
	root.add_child(_boss_box)


# --- binding -----------------------------------------------------------------

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
	if _player != null and _player.has_method("dash_ready_ratio"):
		_dash_bar.set_values(_player.dash_ready_ratio(), 1.0)


func _on_run_started() -> void:
	_refresh_xp()
	_refresh_floor()
	_boss_box.visible = false
	call_deferred("_bind_player_health")
	if RunManager.equipment != null:
		RunManager.equipment.equipment_changed.connect(_refresh_weapon)
	_refresh_weapon()


func _on_floor_cleared(_n: int) -> void:
	## RunManager bumps the floor number right after this signal.
	_refresh_floor.call_deferred()
	_boss_box.visible = false
	call_deferred("_bind_player_health")


func _bind_player_health() -> void:
	if _health_component != null and is_instance_valid(_health_component):
		if _health_component.health_changed.is_connected(_on_health_changed):
			_health_component.health_changed.disconnect(_on_health_changed)
	_health_component = null
	var player: Node = null
	for _attempt in 30:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
		if player != null:
			break
	if player == null:
		return
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc == null:
		return
	if not hc.health_changed.is_connected(_on_health_changed):
		hc.health_changed.connect(_on_health_changed)
	_health_component = hc
	_on_health_changed(hc.current_health, hc.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	_life_bar.segments = maxi(1, int(round(maximum / 10.0)))
	_life_bar.set_values(current, maximum)
	_life_now.text = str(int(ceil(current)))
	_life_max.text = " / %d" % int(maximum)


func _on_boss_encountered(data: BossData) -> void:
	if data == null:
		return
	_boss_name.text = data.get_name_text()
	_boss_box.visible = true
	await get_tree().process_frame
	var boss := get_tree().get_first_node_in_group(&"boss")
	if boss == null:
		return
	var hc: HealthComponent = boss.get_node_or_null("HealthComponent")
	if hc == null:
		return
	_boss_health = hc
	if not hc.health_changed.is_connected(_on_boss_health):
		hc.health_changed.connect(_on_boss_health)
	_on_boss_health(hc.current_health, hc.max_health)


func _on_boss_health(current: float, maximum: float) -> void:
	_boss_bar.set_values(current, maximum)
	if current <= 0.0:
		_boss_box.visible = false


func _refresh_weapon() -> void:
	var weapon: WeaponData = RunManager.equipment.get_weapon() if RunManager.equipment != null else null
	if weapon != null:
		_weapon_icon.texture = weapon.icon
		_weapon_name.text = weapon.get_name_text()
		_weapon_name.add_theme_color_override("font_color", K.item_color(weapon.rarity))
		_weapon_stats.text = "%d %s · %.1f/S" % [int(weapon.damage), tr("HUD_DMG"), weapon.attack_speed]
	else:
		_weapon_icon.texture = null
		_weapon_name.text = tr("HUD_UNARMED")
		_weapon_name.add_theme_color_override("font_color", K.ASH_LT)
		_weapon_stats.text = ""


func _refresh_xp() -> void:
	_xp_bar.set_values(RunManager.xp, RunManager.xp_to_next)
	_lv.text = "%s %d" % [tr("HUD_LV"), RunManager.level]


func _refresh_floor() -> void:
	_floor_num.text = str(RunManager.current_floor)
	_pips.current = RunManager.current_floor
	_pips.queue_redraw()


func _refresh_texts() -> void:
	## Language changed mid-run (pause → settings).
	var floor_row := _floor_num.get_parent()
	(floor_row.get_child(0) as Label).text = tr("HUD_FLOOR")
	_refresh_xp()
	if RunManager.equipment != null:
		_refresh_weapon()
	var dash := get_node_or_null("Control/Dash/DashLabel") as Label
	if dash != null:
		dash.text = tr("HUD_DASH")


func _show_toast(text: String, color: Color) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


## Nine floors: walked ones in gold, this one as a hollow ember, the rest
## dark; Warden floors are red diamonds.
class FloorPips:
	extends Control

	var current: int = 1

	func _init() -> void:
		custom_minimum_size = Vector2(9 * 10 - 4, 8)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in 9:
			var f := i + 1
			var x := i * 10.0
			var r := Rect2(x, 1, 6, 6)
			if f in [3, 6, 9]:
				var c := Vector2(x + 3, 4)
				var pts := PackedVector2Array([c + Vector2(0, -4), c + Vector2(4, 0), c + Vector2(0, 4), c + Vector2(-4, 0)])
				draw_colored_polygon(pts, UIKit.VOID)
				var inner := PackedVector2Array([c + Vector2(0, -3), c + Vector2(3, 0), c + Vector2(0, 3), c + Vector2(-3, 0)])
				var col := UIKit.GOLD if f < current else (UIKit.ROSE if f == current else UIKit.BLOOD)
				draw_colored_polygon(inner, col if f <= current else UIKit.BLOOD_DK)
				if f > current:
					draw_polyline(PackedVector2Array([inner[0], inner[1], inner[2], inner[3], inner[0]]), UIKit.BLOOD, 1.0)
			else:
				draw_rect(r.grow(1), UIKit.VOID)
				if f < current:
					draw_rect(r, UIKit.GOLD)
				elif f == current:
					draw_rect(r, UIKit.GOLD_LT)
					draw_rect(r.grow(-1), UIKit.EMBER)
				else:
					draw_rect(r, UIKit.SLATE_3)

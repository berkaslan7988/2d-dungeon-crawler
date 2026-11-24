## Screenshot runner (not part of the game). Plays through the screens and
## saves PNGs of the real window:
##   godot --path . res://tools/shots/Shots.tscn -- out=<dir> lang=en
## Writes to user:// for saves like the game does.
extends Node

var _out: String = "user://shots"
var _lang: String = "en"
var _only: String = ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			_out = a.substr(4)
		elif a.begins_with("lang="):
			_lang = a.substr(5)
		elif a.begins_with("only="):
			_only = a.substr(5)
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_out.path_join("%s-%s.png" % [name, _lang]))
	print("shot ", name)


func _press(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


func _player() -> Node2D:
	return get_tree().get_first_node_in_group(Constants.GROUP_PLAYER) as Node2D


func _run() -> void:
	## Survive scene changes: hand "current scene" to a placeholder.
	var tree := get_tree()
	var placeholder := Node.new()
	tree.root.add_child(placeholder)
	tree.current_scene = placeholder
	Settings.set_language(_lang)
	seed(7)

	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	await _wait(1.2)
	await _shot("title")

	get_tree().change_scene_to_file("res://scenes/world/Main.tscn")
	await _wait(3.5)
	await _shot("story")
	await _press(&"ui_accept")
	await _wait(0.3)
	await _press(&"ui_accept")
	await _wait(0.8)

	# a few items in the bag and a sword in hand
	for id in ["iron_sword", "leather_armor", "health_potion", "health_potion", "slime_goo", "war_hammer"]:
		RunManager.inventory.add_item(load("res://data/items/%s.tres" % id), 1)
	var sword: ItemData = load("res://data/items/iron_sword.tres")
	RunManager.equipment.equip(sword)
	RunManager.inventory.remove_item(sword, 1)
	await _wait(1.0)
	await _shot("start")
	# walk into the nearest pack and swing
	var p0 := _player()
	var foes := get_tree().get_nodes_in_group(Constants.GROUP_ENEMIES)
	if p0 != null and not foes.is_empty():
		foes.sort_custom(func(a, b) -> bool:
			return a.global_position.distance_to(p0.global_position) < b.global_position.distance_to(p0.global_position))
		var target: Node2D = foes[0]
		p0.global_position = target.global_position + Vector2(-34, 10)
		await _wait(1.4)
		var v := get_viewport()
		v.warp_mouse(v.get_visible_rect().size / 2 + Vector2(60, -20))
		await _press(&"attack")
		await _wait(0.05)
	await _shot("game")

	EventBus.player_leveled_up.emit(5)
	await _wait(0.8)
	await _shot("boon")
	await _press(&"ui_accept")
	await _wait(0.6)

	await _press(&"inventory")
	await _wait(0.4)
	await _shot("inventory")
	await _press(&"inventory")
	await _wait(0.3)

	await _press(&"pause")
	await _wait(0.4)
	await _shot("pause")
	await _press(&"pause")
	await _wait(0.3)

	# straight to the last Warden
	RunManager.current_floor = 8
	RunManager.go_to_next_floor()
	await _wait(1.5)
	var boss := get_tree().get_first_node_in_group(&"boss") as Node2D
	var p := _player()
	if boss != null and p != null:
		p.global_position = boss.global_position + Vector2(0, 70)
	await _wait(2.6)
	await _shot("warden")
	await _press(&"ui_accept")
	await _wait(0.3)
	await _press(&"ui_accept")
	await _wait(1.0)
	await _shot("bossfight")

	EventBus.run_ended.emit(false)
	await _wait(1.8)
	await _shot("end")
	get_tree().quit()

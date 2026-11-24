## DialogueScreen — story and Warden dialogue. Pauses the run while shown.
## A Warden speaks from a box at the bottom with their portrait; the opening
## story is a full-screen card under the eclipse mark. Text types out; E,
## Q, Enter or a click finishes the line, then moves on.
extends CanvasLayer

const K = preload("res://scenes/ui/ui_kit.gd")
const TYPE_SPEED: float = 55.0   ## characters per second

## Queue entry: {title, body, portrait (Texture2D or null), on_done}
var _queue: Array = []
var _showing: bool = false
var _current_on_done: Callable = Callable()
var _typing: Tween

var _root: Control
var _box: PanelContainer
var _portrait: TextureRect
var _name: Label
var _body: Label
var _story: VBoxContainer
var _story_title: Label
var _story_body: Label
var _active_body: Label


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	for c in get_children():
		c.queue_free()
	_build()
	hide()
	EventBus.story_requested.connect(func(t: String, b: String) -> void: _enqueue(t, b, null, Callable()))
	EventBus.boss_encountered.connect(_on_boss_encountered)
	EventBus.boss_defeated.connect(_on_boss_defeated)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# story card
	_story = K.vbox(10)
	_story.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story.alignment = BoxContainer.ALIGNMENT_CENTER
	var scrim := K.scrim(0.94)
	_root.add_child(scrim)
	scrim.visible = false
	_story.set_meta("scrim", scrim)
	_root.add_child(_story)
	var mark := K.icon(K.MARK, 2)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_story.add_child(mark)
	_story_title = K.title("", 34)
	_story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story.add_child(_story_title)
	var wrap := CenterContainer.new()
	_story.add_child(wrap)
	_story_body = K.label("", 11, K.PARCH)
	_story_body.custom_minimum_size = Vector2(430, 0)
	_story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_body.add_theme_constant_override("line_spacing", 3)
	wrap.add_child(_story_body)
	_story.add_child(_continue_row(true))

	# speaker box
	_box = K.panel(10, K.SLATE_3, Color(K.SOOT, 0.97))
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 56
	_box.offset_right = -56
	_box.offset_top = -122
	_box.offset_bottom = -16
	_root.add_child(_box)
	var row := K.hbox(12)
	_box.add_child(row)
	var frame := K.panel(2, K.EMBER_DK, K.VOID)
	frame.custom_minimum_size = Vector2(72, 84)
	_portrait = K.icon(null)
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_portrait.custom_minimum_size = Vector2(64, 80)
	frame.add_child(_portrait)
	row.add_child(frame)
	var text := K.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	_name = K.title("", 22, K.GOLD)
	_name.remove_theme_color_override("font_shadow_color")
	text.add_child(_name)
	_body = K.label("", 11, K.PARCH)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("line_spacing", 2)
	text.add_child(_body)
	text.add_child(_continue_row(false))


func _continue_row(centered: bool) -> HBoxContainer:
	var r := K.hbox(4)
	r.alignment = BoxContainer.ALIGNMENT_CENTER if centered else BoxContainer.ALIGNMENT_END
	r.add_child(K.key_cap("E", true))
	var l := K.num(tr("COMMON_CONTINUE"), 11, K.ASH_LT)
	l.name = "ContinueLabel"
	r.add_child(l)
	return r


func _unhandled_input(event: InputEvent) -> void:
	if not _showing:
		return
	var go: bool = event.is_action_pressed("inventory") or event.is_action_pressed("interact") \
			or event.is_action_pressed("ui_accept") \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if go:
		get_viewport().set_input_as_handled()
		if _typing != null and _typing.is_valid() and _typing.is_running():
			_typing.kill()
			_active_body.visible_ratio = 1.0
		else:
			_on_continue()


func _on_boss_encountered(data: BossData) -> void:
	if data == null:
		return
	_enqueue(data.get_name_text(), data.get_intro_text(), _portrait_of(data), Callable())


func _on_boss_defeated(data: BossData) -> void:
	if data == null:
		return
	var on_done := Callable()
	if data.is_final:
		on_done = func() -> void: RunManager.end_run(true)
	_enqueue(data.get_name_text(), data.get_defeat_text(), _portrait_of(data), on_done)


func _portrait_of(data: BossData) -> Texture2D:
	if data.sprite_frames == null or not data.sprite_frames.has_animation(&"idle"):
		return null
	var tex := data.sprite_frames.get_frame_texture(&"idle", 0)
	## 2× so the Warden fills the frame.
	var img := tex.get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _enqueue(title: String, body: String, portrait: Texture2D, on_done: Callable) -> void:
	_queue.append({"title": title, "body": body, "portrait": portrait, "on_done": on_done})
	if not _showing:
		_advance()


func _advance() -> void:
	if _queue.is_empty():
		_close()
		return
	_showing = true
	var e: Dictionary = _queue.pop_front()
	_current_on_done = e["on_done"]
	var is_story: bool = e["portrait"] == null
	_story.visible = is_story
	(_story.get_meta("scrim") as Control).visible = is_story
	_box.visible = not is_story
	for l in _root.find_children("ContinueLabel", "Label", true, false):
		(l as Label).text = tr("COMMON_CONTINUE")
	if is_story:
		_story_title.text = e["title"]
		_active_body = _story_body
	else:
		_name.text = e["title"]
		_portrait.texture = e["portrait"]
		_active_body = _body
	_active_body.text = e["body"]
	show()
	get_tree().paused = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.2)
	_active_body.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(_active_body, "visible_ratio", 1.0,
			maxf(0.3, _active_body.text.length() / TYPE_SPEED))


func _on_continue() -> void:
	var cb := _current_on_done
	_current_on_done = Callable()
	if _queue.is_empty():
		_close()
	else:
		_advance()
	if cb.is_valid():
		cb.call()


func _close() -> void:
	_showing = false
	hide()
	get_tree().paused = false

## MainMenu — the title screen: the eclipse crown, the name, four choices.
## Descend starts a run; the Altar of Souls (meta shop) and Settings open as
## overlays; Quit is hidden on the web build.
extends Control

const K = preload("res://scenes/ui/ui_kit.gd")
const GAME_SCENE: String = "res://scenes/world/Main.tscn"
const BG: Texture2D = preload("res://assets/ui/title_bg.png")

var _menu: VBoxContainer
var _settings: SettingsPanel
var _altar: AltarPanel
var _last_focus: Control
var _lang: String = ""


func _ready() -> void:
	LightManager.clear_fog()
	for c in get_children():
		c.queue_free()
	_build()
	Settings.changed.connect(_on_settings_changed)
	EventBus.music_requested.emit(&"dungeon")


func _build() -> void:
	_lang = Settings.language
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bg)
	add_child(_motes())

	var head := K.vbox(2)
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	head.offset_top = 150
	head.offset_left = -240
	head.offset_right = 240
	add_child(head)
	var title := K.title(tr("GAME_TITLE"), 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	var tag := K.shadowed(K.label(tr("TITLE_TAGLINE"), 10, K.BONE))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(tag)

	_menu = K.vbox(0)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_menu.offset_top = 232
	_menu.offset_left = -100
	_menu.offset_right = 100
	add_child(_menu)
	_entry(tr("TITLE_DESCEND"), _on_start)
	_entry(tr("TITLE_ALTAR"), _open_altar)
	_entry(tr("TITLE_SETTINGS"), _open_settings)
	if not OS.has_feature("web"):
		_entry(tr("TITLE_QUIT"), func() -> void: get_tree().quit())

	# bottom bar
	var bar := K.hbox(10)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 16
	bar.offset_right = -16
	bar.offset_top = -24
	bar.offset_bottom = -9
	add_child(bar)
	var souls := K.hbox(4)
	var si := K.icon(K.SOUL_ICON)
	si.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	souls.add_child(si)
	souls.add_child(K.shadowed(K.num(_thousands(GameManager.meta_currency), 15, K.GOLD)))
	souls.add_child(K.shadowed(K.num(tr("COMMON_SOULS"), 11, K.ASH_LT)))
	if GameManager.best_floor > 0:
		souls.add_child(K.shadowed(K.num("· %s %d" % [tr("TITLE_BEST_FLOOR"), GameManager.best_floor], 11, K.ASH_LT)))
	for c in souls.get_children():
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	souls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(souls)
	var hint := K.shadowed(K.num(tr("TITLE_HINT"), 11, K.ASH_LT))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(hint)
	var right := K.hbox(2)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	for code in Settings.LANGUAGES:
		var b := K.button(code.to_upper(), 10)
		b.focus_mode = Control.FOCUS_NONE
		if Settings.language == code:
			b.add_theme_stylebox_override("normal", K.frame(K.SLATE_1, K.GOLD, 1, 0))
			(b.get_theme_stylebox("normal") as StyleBoxFlat).content_margin_left = 8
			(b.get_theme_stylebox("normal") as StyleBoxFlat).content_margin_right = 8
			b.add_theme_color_override("font_color", K.PARCH)
		b.pressed.connect(func() -> void: Settings.set_language(code))
		right.add_child(b)
	var ver := K.shadowed(K.num("  V" + str(ProjectSettings.get_setting("application/config/version", "")), 11, K.ASH_LT))
	ver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(ver)
	bar.add_child(right)

	_settings = SettingsPanel.new()
	_settings.closed.connect(_restore_focus)
	add_child(_settings)
	_altar = AltarPanel.new()
	_altar.closed.connect(func() -> void:
		_rebuild())
	add_child(_altar)

	(_menu.get_child(0).get_child(1) as Button).grab_focus.call_deferred()


## One menu line: an ember caret that shows on the focused entry.
func _entry(text: String, action: Callable) -> void:
	var row := K.hbox(6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var caret := K.icon(K.EMBER_ICON)
	caret.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caret.modulate.a = 0.0
	row.add_child(caret)
	var b := K.menu_button(text, 14)
	b.pressed.connect(action)
	b.focus_entered.connect(func() -> void:
		caret.modulate.a = 1.0
		_last_focus = b)
	b.focus_exited.connect(func() -> void: caret.modulate.a = 0.0)
	row.add_child(b)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(6, 0)
	row.add_child(spacer)
	_menu.add_child(row)


func _motes() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(320, 380)
	p.amount = 40
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(220, 10)
	p.direction = Vector2(0, -1)
	p.spread = 12.0
	p.gravity = Vector2(0, -2)
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 30.0
	var grad := Gradient.new()
	grad.set_color(0, Color(K.GOLD, 0.0))
	grad.set_color(1, Color(K.EMBER, 0.0))
	grad.add_point(0.15, K.GOLD_LT)
	grad.add_point(0.7, K.FLAME)
	p.color_ramp = grad
	return p


func _on_start() -> void:
	EventBus.sfx_requested.emit(&"ui_click")
	GameManager.change_scene(GAME_SCENE)


func _open_settings() -> void:
	_settings.open()


func _open_altar() -> void:
	_altar.open()


func _restore_focus() -> void:
	if _last_focus != null and is_instance_valid(_last_focus):
		_last_focus.grab_focus()


func _on_settings_changed() -> void:
	## Only a language switch rebuilds the screen; keep Settings open if it was.
	if Settings.language == _lang:
		return
	_rebuild(_settings != null and _settings.visible)


func _rebuild(reopen_settings: bool = false) -> void:
	for c in get_children():
		c.queue_free()
	_build()
	if reopen_settings:
		_settings.open.call_deferred()


static func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

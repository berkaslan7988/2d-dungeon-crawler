## SettingsPanel — language, volume, fullscreen, screen shake. Opened from
## the title screen and the pause menu; everything saves as it changes.
class_name SettingsPanel
extends Control

signal closed

const K = preload("res://scenes/ui/ui_kit.gd")

var _lang_buttons: Dictionary = {}
var _first: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open() -> void:
	_rebuild()
	visible = true
	_first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	visible = false
	closed.emit()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	add_child(K.scrim(0.8))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := K.panel(14)
	panel.custom_minimum_size = Vector2(300, 0)
	center.add_child(panel)
	var col := K.vbox(8)
	panel.add_child(col)
	var head := K.title(tr("SETTINGS_TITLE"), 30)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)

	var lang := K.hbox(2)
	for code in Settings.LANGUAGES:
		var b := K.button(code.to_upper(), 10)
		b.toggle_mode = true
		b.button_pressed = Settings.language == code
		b.pressed.connect(func() -> void:
			Settings.set_language(code)
			_rebuild())
		_lang_buttons[code] = b
		lang.add_child(b)
	_first = _lang_buttons[Settings.language]
	col.add_child(_row(tr("SETTINGS_LANGUAGE"), lang))
	col.add_child(_row(tr("SETTINGS_MASTER"), _slider("master", Settings.master_volume)))
	col.add_child(_row(tr("SETTINGS_MUSIC"), _slider("music", Settings.music_volume)))
	col.add_child(_row(tr("SETTINGS_SFX"), _slider("sfx", Settings.sfx_volume)))
	col.add_child(_row(tr("SETTINGS_FULLSCREEN"), _toggle(Settings.fullscreen, Settings.set_fullscreen)))
	col.add_child(_row(tr("SETTINGS_SHAKE"), _toggle(Settings.screen_shake, Settings.set_screen_shake)))

	var back := K.button(tr("COMMON_BACK"), 10)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	col.add_child(back)


func _rebuild() -> void:
	var had_focus := visible
	_build()
	if had_focus:
		_first.grab_focus.call_deferred()


func _row(text: String, control: Control) -> HBoxContainer:
	var row := K.hbox(10)
	var l := K.label(text, 10, K.BONE)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(120, 0)
	row.add_child(l)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	return row


func _slider(which: String, value: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(120, 10)
	s.focus_mode = Control.FOCUS_ALL
	var track := K.frame(K.SLATE_2, K.VOID, 1, 0)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var filled := K.frame(K.FLAME, K.VOID, 1, 0)
	filled.content_margin_top = 2
	filled.content_margin_bottom = 2
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", filled)
	s.add_theme_stylebox_override("grabber_area_highlight", filled)
	s.add_theme_icon_override("grabber", _grabber(K.BONE))
	s.add_theme_icon_override("grabber_highlight", _grabber(K.GOLD_LT))
	s.value_changed.connect(func(v: float) -> void: Settings.set_volume(which, v))
	return s


func _toggle(on: bool, setter: Callable) -> Button:
	var b := K.button(tr("COMMON_ON") if on else tr("COMMON_OFF"), 10)
	b.custom_minimum_size = Vector2(52, 0)
	b.pressed.connect(func() -> void:
		var now := b.text != tr("COMMON_ON")
		setter.call(now)
		b.text = tr("COMMON_ON") if now else tr("COMMON_OFF"))
	return b


static func _grabber(c: Color) -> ImageTexture:
	var img := Image.create(4, 10, false, Image.FORMAT_RGBA8)
	img.fill(UIKit.VOID)
	img.fill_rect(Rect2i(1, 1, 2, 8), c)
	return ImageTexture.create_from_image(img)

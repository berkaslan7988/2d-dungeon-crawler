## Settings — player preferences that outlive a run: language, volume,
## fullscreen, screen shake. Saved to user://settings.json. Autoload: Settings
extends Node

signal changed

const PATH: String = "user://settings.json"
const LANGUAGES: Array[String] = ["en", "tr"]

var language: String = "en"
var master_volume: float = 0.8
var music_volume: float = 0.6
var sfx_volume: float = 0.9
var fullscreen: bool = false
var screen_shake: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	language = "tr" if OS.get_locale_language() == "tr" else "en"
	_load()
	TranslationServer.set_locale(language)
	_apply_window()
	## AudioManager is created after us; set its buses once it exists.
	call_deferred("_apply_audio")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		set_fullscreen(not fullscreen)
		get_viewport().set_input_as_handled()


func set_language(code: String) -> void:
	if code not in LANGUAGES or code == language:
		return
	language = code
	TranslationServer.set_locale(code)
	_save_and_notify()


func set_volume(which: String, value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	match which:
		"master":
			master_volume = value
		"music":
			music_volume = value
		"sfx":
			sfx_volume = value
	_apply_audio()
	_save_and_notify()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_window()
	_save_and_notify()


func set_screen_shake(on: bool) -> void:
	screen_shake = on
	_save_and_notify()


func _apply_audio() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am == null:
		return
	am.set_bus_volume("Master", master_volume)
	am.set_bus_volume("Music", music_volume)
	am.set_bus_volume("SFX", sfx_volume)


func _apply_window() -> void:
	## On the web, fullscreen needs a click; the browser decides.
	if OS.has_feature("web") and not fullscreen:
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _save_and_notify() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"language": language,
			"master": master_volume,
			"music": music_volume,
			"sfx": sfx_volume,
			"fullscreen": fullscreen,
			"screen_shake": screen_shake,
		}, "\t"))
	changed.emit()


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var lang: String = str(parsed.get("language", language))
	if lang in LANGUAGES:
		language = lang
	master_volume = float(parsed.get("master", master_volume))
	music_volume = float(parsed.get("music", music_volume))
	sfx_volume = float(parsed.get("sfx", sfx_volume))
	fullscreen = bool(parsed.get("fullscreen", fullscreen))
	screen_shake = bool(parsed.get("screen_shake", screen_shake))

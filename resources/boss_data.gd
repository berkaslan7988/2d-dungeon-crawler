## BossData — Faz 10 (hikaye): bir boss'un kimliğini, istatistiklerini ve
## diyaloglarını (savaş öncesi/sonrası) tanımlar. Boss.tscn tek sahne;
## farklı BossData = farklı boss (Garoth / Myrra / Vorlak).
class_name BossData
extends Resource

## Translation key stem: BOSS_<key>_NAME / _TITLE / _INTRO / _DEFEAT.
@export var key: String = ""
@export var display_name: String = "Boss"
@export_multiline var intro_text: String = ""    ## savaştan önce söyledikleri
@export_multiline var defeat_text: String = ""   ## yenilince söyledikleri
## true ise bu boss yenilince RUN ZAFERLE biter (final boss).
@export var is_final: bool = false

@export_group("Görünüm")
@export var sprite_frames: SpriteFrames
@export var sprite_tint: Color = Color(0.85, 0.3, 0.35, 1)
@export var sprite_scale: float = 2.4

@export_group("İstatistik")
@export var max_health: float = 320.0
@export var move_speed: float = 34.0
@export var slam_damage: float = 22.0
@export var volley_damage: float = 9.0
@export var volley_count: int = 10
@export var summon_count: int = 3


## Localised text, falling back to the Turkish fields in the .tres.
func get_name_text() -> String:
	return _t("NAME", display_name)


func get_title_text() -> String:
	return _t("TITLE", "")


func get_intro_text() -> String:
	return _t("INTRO", intro_text)


func get_defeat_text() -> String:
	return _t("DEFEAT", defeat_text)


func _t(part: String, fallback: String) -> String:
	if key == "":
		return fallback
	var k := "BOSS_%s_%s" % [key, part]
	var s := TranslationServer.translate(k)
	return fallback if s == k else s

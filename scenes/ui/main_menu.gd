## MainMenu — Faz 10 (kullanıcı isteği): oyunun açılış ekranı. Buradan oyun
## başlatılır (Main.tscn'e geçilir) veya çıkılır. Pause menüsündeki "Ana Menü"
## ve ölüm/zafer ekranı da buraya döner.
extends Control

const GAME_SCENE: String = "res://scenes/world/Main.tscn"

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var quit_btn: Button = $Center/VBox/QuitBtn
@onready var info_label: Label = $Center/VBox/InfoLabel


func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	quit_btn.pressed.connect(_on_quit)
	## Kalıcı ilerleme özeti (meta).
	info_label.text = "Kalıcı ruh: %d        En derin kat: %d" % [
		GameManager.meta_currency, GameManager.best_floor
	]
	start_btn.grab_focus()


func _on_start() -> void:
	GameManager.change_scene(GAME_SCENE)


func _on_quit() -> void:
	get_tree().quit()

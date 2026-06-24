## DeathScreen — run bitişinde (ölüm veya zafer) gösterilen özet ekranı.
## EventBus.run_ended(victory) sinyaline bağlanır.
## Run özeti: kat, öldürülen düşman, ulaşılan level, kazanılan meta para.
## process_mode = ALWAYS: oyun dururken de tıklanabilir olması için.
extends CanvasLayer

@onready var panel:          Control = $Panel
@onready var title_label:    Label   = $Panel/VBox/Title
@onready var summary_label:  Label   = $Panel/VBox/Summary
@onready var retry_btn:      Button  = $Panel/VBox/Buttons/RetryBtn
@onready var menu_btn:       Button  = $Panel/VBox/Buttons/MenuBtn

const COLOR_DEATH   := Color("e74c3c")
const COLOR_VICTORY := Color("f1c40f")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	EventBus.run_ended.connect(_on_run_ended)


func _on_run_ended(victory: bool) -> void:
	## Kısa gecikme: ölüm animasyonu/fade bittikten sonra ekran açılsın.
	await get_tree().create_timer(0.8).timeout
	_populate(victory)
	_open()


func _populate(victory: bool) -> void:
	if victory:
		title_label.text = "ZAFERİN KUTLU OLSUN!"
		title_label.add_theme_color_override("font_color", COLOR_VICTORY)
	else:
		title_label.text = "ÖLDÜN!"
		title_label.add_theme_color_override("font_color", COLOR_DEATH)

	## Run istatistikleri (RunManager ve GameManager'dan al)
	var floor_reached := RunManager.current_floor
	var killed        := RunManager.enemies_killed
	var lvl           := RunManager.level
	## Ödül GameManager._on_run_ended'da hesaplanıp saklandı (tek kaynak).
	var earned        := GameManager.last_run_reward
	## Faz 8 UX: roadmap'in açıkça istediği "süre" alanı.
	var duration      := RunManager.get_run_duration()
	var duration_sec  := int(duration)
	@warning_ignore("integer_division")
	var duration_str  := "%d:%02d" % [duration_sec / 60, duration_sec % 60]

	summary_label.text = (
		"Ulaşılan Kat : %d\n"
		+ "Öldürülen    : %d düşman\n"
		+ "Level        : %d\n"
		+ "Süre         : %s\n"
		+ "Kazanılan    : 💀 %d ruh"
	) % [floor_reached, killed, lvl, duration_str, earned]


func _open() -> void:
	show()
	## Oyunu durdur: altta düşmanlar gezmeye devam etmesin. DeathScreen
	## process_mode=ALWAYS olduğu için butonlar yine çalışır; retry/menu
	## get_tree().paused=false ile devam ettirir.
	get_tree().paused = true
	## Fade-in animasyonu
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.4)


func _on_retry_pressed() -> void:
	hide()
	## Oyun tree'sini durdurmuş olabilir (UpgradeScreen vs.) — sıfırla
	get_tree().paused = false
	RunManager.start_run()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	hide()
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

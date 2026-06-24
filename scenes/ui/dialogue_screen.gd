## DialogueScreen — Faz 10 (hikaye): anlatı/diyalog kutusu.
## Üç kaynağı dinler: genel hikaye (story_requested), boss karşılaşması
## (boss_encountered → intro), boss yenilgisi (boss_defeated → defeat + final
## ise zafer). Gösterilirken oyunu duraklatır; sırayla kuyruğu boşaltır.
extends CanvasLayer

@onready var panel: Control = $Panel
@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var body_label: Label = $Panel/VBox/BodyLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn

## Kuyruk elemanı: {title: String, body: String, on_done: Callable}
var _queue: Array = []
var _showing: bool = false
var _current_on_done: Callable = Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	EventBus.story_requested.connect(_on_story)
	EventBus.boss_encountered.connect(_on_boss_encountered)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	continue_btn.pressed.connect(_on_continue)


## Duraklatılmışken de "Devam" tuş/buton ile geçilebilsin.
func _unhandled_input(event: InputEvent) -> void:
	if not _showing:
		return
	## "E" (inventory action), Q (interact), Enter/Space (ui_accept) ile geç.
	if event.is_action_pressed("inventory") or event.is_action_pressed("interact") \
			or event.is_action_pressed("ui_accept"):
		_on_continue()
		get_viewport().set_input_as_handled()


## --- Kaynaklar ---

func _on_story(title: String, body: String) -> void:
	_enqueue(title, body, Callable())


func _on_boss_encountered(data: BossData) -> void:
	if data == null:
		return
	_enqueue(data.display_name, data.intro_text, Callable())


func _on_boss_defeated(data: BossData) -> void:
	if data == null:
		return
	var on_done := Callable()
	if data.is_final:
		## Final boss: diyalog kapanınca zaferi başlat.
		on_done = func() -> void: RunManager.end_run(true)
	_enqueue(data.display_name, data.defeat_text, on_done)


## --- Kuyruk / gösterim ---

func _enqueue(title: String, body: String, on_done: Callable) -> void:
	_queue.append({"title": title, "body": body, "on_done": on_done})
	if not _showing:
		_advance()


func _advance() -> void:
	if _queue.is_empty():
		_close()
		return
	_showing = true
	var entry: Dictionary = _queue.pop_front()
	_current_on_done = entry["on_done"]
	name_label.text = entry["title"]
	body_label.text = entry["body"]
	show()
	get_tree().paused = true
	continue_btn.grab_focus()
	## Küçük yumuşak giriş.
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)


func _on_continue() -> void:
	var cb := _current_on_done
	_current_on_done = Callable()
	if _queue.is_empty():
		_close()
	else:
		_advance()
	## on_done en son çağrılır (ör. final zafer ekranı duraklatmayı devralır).
	if cb.is_valid():
		cb.call()


func _close() -> void:
	_showing = false
	hide()
	get_tree().paused = false

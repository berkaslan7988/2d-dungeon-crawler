## ChestScreen — Faz 10 (kullanıcı isteği): sandık açılınca oyunu durdurur,
## içindeki eşyaları (+ varsa yetenek) listeler; "Hepsini Al" ile hepsi
## envantere eklenir (yetenek uygulanır), ekran kapanır ve oyun devam eder.
extends CanvasLayer

@onready var panel: Control = $Panel
@onready var items_box: VBoxContainer = $Panel/VBox/ItemsBox
@onready var upgrade_label: Label = $Panel/VBox/UpgradeLabel
@onready var take_btn: Button = $Panel/VBox/TakeBtn

var _items: Array = []
var _upgrade: UpgradeData = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	EventBus.chest_opened.connect(_on_chest_opened)
	take_btn.pressed.connect(_on_take)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	## "E" (inventory action), Q (interact), Enter/Space ile "Hepsini Al".
	if event.is_action_pressed("inventory") or event.is_action_pressed("interact") \
			or event.is_action_pressed("ui_accept"):
		_on_take()
		get_viewport().set_input_as_handled()


func _on_chest_opened(items: Array, upgrade: UpgradeData) -> void:
	_items = items
	_upgrade = upgrade
	_build()
	show()
	get_tree().paused = true
	take_btn.grab_focus()
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.18)


func _build() -> void:
	for child in items_box.get_children():
		child.queue_free()

	## Aynı eşyaları say (x adet göster).
	var counts: Dictionary = {}
	var order: Array = []
	for it in _items:
		if not counts.has(it):
			counts[it] = 0
			order.append(it)
		counts[it] += 1

	if order.is_empty() and _upgrade == null:
		var empty := Label.new()
		empty.text = "(Sandık boştu...)"
		items_box.add_child(empty)

	for it in order:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		if it.icon != null:
			var icon := TextureRect.new()
			icon.texture = it.icon
			icon.custom_minimum_size = Vector2(20, 20)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)

		var lbl := Label.new()
		var n: int = counts[it]
		lbl.text = "%s%s" % [it.display_name, (" x%d" % n) if n > 1 else ""]
		## Kullanıcı isteği: sandıktaki tüm eşyalar yeşil gösterilir.
		lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		row.add_child(lbl)
		items_box.add_child(row)

	if _upgrade != null:
		upgrade_label.visible = true
		upgrade_label.text = "✦ Yetenek: %s — %s" % [_upgrade.display_name, _upgrade.description]
		upgrade_label.add_theme_color_override("font_color", _upgrade.get_color())
	else:
		upgrade_label.visible = false


func _on_take() -> void:
	if RunManager.inventory != null:
		for it in _items:
			RunManager.inventory.add_item(it, 1)
	if _upgrade != null:
		RunManager.confirm_upgrade(_upgrade)
	_items = []
	_upgrade = null
	hide()
	get_tree().paused = false

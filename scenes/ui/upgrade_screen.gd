## UpgradeScreen — level-up ekranı.
## EventBus.player_leveled_up sinyali tetiklenince açılır, oyunu durdurur,
## 3 upgrade kartı sunar. Oyuncu seçim yapınca kapanır, oyun devam eder.
##
## Bu CanvasLayer (layer=10) Faz 8'deki UILayer'a taşınacak.
## Şimdilik Main sahnesi veya DungeonScene'e child olarak ekle:
##   var upgrade_screen = preload("res://scenes/ui/UpgradeScreen.tscn").instantiate()
##   add_child(upgrade_screen)
##
## process_mode = ALWAYS — oyun dursa bile bu node çalışmaya devam eder.
extends CanvasLayer

## Kart başına arka plan rengi (rarity'e göre seçilir).
const RARITY_BG: Dictionary = {
	UpgradeData.Rarity.COMMON:   Color("1a1a2e"),
	UpgradeData.Rarity.UNCOMMON: Color("0d2818"),
	UpgradeData.Rarity.RARE:     Color("0a1a35"),
}

const CARD_MIN_SIZE := Vector2(140, 180)

@onready var cards_row: HBoxContainer = $CenterContainer/CardsRow
@onready var title_label: Label = $CenterContainer/Title
@onready var center_container: VBoxContainer = $CenterContainer

var _current_choices: Array[UpgradeData] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	EventBus.player_leveled_up.connect(_on_player_leveled_up)


func _on_player_leveled_up(new_level: int) -> void:
	title_label.text = "SEVİYE %d!" % new_level
	_current_choices = RunManager.offer_upgrades()

	if _current_choices.is_empty():
		## Upgrade pool yoksa veya boşsa ekranı açma.
		push_warning("UpgradeScreen: upgrade_pool boş, ekran açılmıyor.")
		return

	_build_cards()
	_open()


## --- Kart oluşturma ---

func _build_cards() -> void:
	## Eski kartları temizle.
	for child in cards_row.get_children():
		child.queue_free()

	for upgrade in _current_choices:
		var card := _make_card(upgrade)
		cards_row.add_child(card)


func _make_card(upgrade: UpgradeData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_MIN_SIZE

	## Arka plan stili (rarity rengi).
	var style := StyleBoxFlat.new()
	style.bg_color = RARITY_BG.get(upgrade.rarity, Color("1a1a2e"))
	style.border_color = upgrade.get_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	## Rarity etiket.
	var rarity_names := ["COMMON", "UNCOMMON", "RARE"]
	var rarity_label := Label.new()
	rarity_label.text = rarity_names[upgrade.rarity]
	rarity_label.add_theme_color_override("font_color", upgrade.get_color())
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(rarity_label)

	## İkon (varsa).
	if upgrade.icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = upgrade.icon
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon_rect)

	## İsim.
	var name_label := Label.new()
	name_label.text = upgrade.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	## Açıklama.
	var desc_label := RichTextLabel.new()
	desc_label.text = upgrade.description
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.add_theme_font_size_override("normal_font_size", 10)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	## Seçim butonu.
	var btn := Button.new()
	btn.text = "SEÇ"
	btn.add_theme_color_override("font_color", upgrade.get_color())
	btn.pressed.connect(_on_card_selected.bind(upgrade))
	vbox.add_child(btn)

	return panel


## --- Açma / kapama ---

func _open() -> void:
	show()
	get_tree().paused = true
	## Animasyon: ekran ortadan büyüyerek açılır.
	center_container.scale = Vector2(0.7, 0.7)
	center_container.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(center_container, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_container, "modulate:a", 1.0, 0.15)


func _close() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(center_container, "scale", Vector2(0.8, 0.8), 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(center_container, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	hide()
	get_tree().paused = false


## --- Seçim ---

func _on_card_selected(upgrade: UpgradeData) -> void:
	RunManager.confirm_upgrade(upgrade)
	_close()

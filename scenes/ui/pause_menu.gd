## PauseMenu — ESC ile açılıp kapanan durdurma menüsü.
## process_mode = ALWAYS: oyun durmuşken bile butonlar çalışır.
## UpgradeScreen açıkken pause devre dışı (çakışma engeli).
##
## Faz 7/9: Mağaza — GameManager.meta_shop_pool'daki UpgradeData'ları kalıcı
## para (meta_currency) ile satın alma ekranı. upgrade_screen.gd'deki kart
## oluşturma deseni burada da (cost/owned durumu eklenerek) kullanılıyor.
extends CanvasLayer

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"

@onready var panel: Control = $Panel
@onready var shop_panel: Control = $ShopPanel
@onready var confirm_panel: Control = $ConfirmPanel
@onready var shop_currency_label: Label = $ShopPanel/VBox/Header/CurrencyLabel
@onready var shop_cards_grid: GridContainer = $ShopPanel/VBox/ScrollContainer/CardsGrid


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	shop_panel.hide()
	confirm_panel.hide()
	EventBus.meta_currency_changed.connect(_on_currency_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	## Upgrade seçim ekranı açıkken pause açılmasın.
	if get_tree().paused and not visible:
		return
	if visible:
		## ESC önceliği: onay > mağaza > resume.
		if confirm_panel.visible:
			_on_confirm_no()
		elif shop_panel.visible:
			_on_shop_back_pressed()
		else:
			_resume()
	else:
		_open()


func _open() -> void:
	show()
	panel.show()
	shop_panel.hide()
	confirm_panel.hide()
	get_tree().paused = true
	## Küçük animasyon: panel yukarıdan kayarak gelir.
	panel.modulate.a = 0.0
	panel.position.y = -20.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(panel, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD)


func _resume() -> void:
	hide()
	get_tree().paused = false


func _on_resume_pressed() -> void:
	_resume()


## "Ana Menü" → önce onay sor (ilerleme kaybı uyarısı).
func _on_main_menu_pressed() -> void:
	panel.hide()
	shop_panel.hide()
	confirm_panel.show()


func _on_confirm_no() -> void:
	confirm_panel.hide()
	panel.show()


func _on_confirm_yes() -> void:
	get_tree().paused = false
	GameManager.change_scene(MAIN_MENU_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


## --- Mağaza ---

func _on_shop_pressed() -> void:
	panel.hide()
	shop_panel.show()
	_refresh_shop()


func _on_shop_back_pressed() -> void:
	shop_panel.hide()
	panel.show()


func _on_currency_changed(_new_total: int) -> void:
	if shop_panel.visible:
		_refresh_shop()


func _refresh_shop() -> void:
	shop_currency_label.text = "* %d" % GameManager.meta_currency

	for child in shop_cards_grid.get_children():
		child.queue_free()

	if GameManager.meta_shop_pool == null:
		return

	for upgrade in GameManager.meta_shop_pool.upgrades:
		shop_cards_grid.add_child(_make_shop_card(upgrade))


## upgrade_screen.gd'deki _make_card() ile aynı görsel dil (rarity rengi,
## rounded border) — buna ek olarak fiyat/sahiplik durumu gösteren bir buton.
func _make_shop_card(upgrade: UpgradeData) -> PanelContainer:
	var shop_panel_card := PanelContainer.new()
	shop_panel_card.custom_minimum_size = Vector2(120, 150)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1a2e")
	style.border_color = upgrade.get_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	shop_panel_card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	shop_panel_card.add_child(vbox)

	var name_label := Label.new()
	name_label.text = upgrade.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var desc_label := RichTextLabel.new()
	desc_label.text = upgrade.description
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.add_theme_font_size_override("normal_font_size", 9)
	desc_label.custom_minimum_size = Vector2(0, 55)
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	var btn := Button.new()
	if GameManager.is_meta_upgrade_purchased(upgrade.id):
		btn.text = "SAHİP"
		btn.disabled = true
	else:
		btn.text = "%d * Satın Al" % upgrade.meta_cost
		btn.disabled = GameManager.meta_currency < upgrade.meta_cost
		btn.pressed.connect(_on_buy_pressed.bind(upgrade))
	vbox.add_child(btn)

	return shop_panel_card


func _on_buy_pressed(upgrade: UpgradeData) -> void:
	if GameManager.purchase_meta_upgrade(upgrade):
		_refresh_shop()

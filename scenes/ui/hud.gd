## HUD — oyun içinde her zaman görünen bilgi katmanı.
## Can barı, XP barı, level, kat göstergesi, meta para.
## Tüm güncellemeler sinyal güdümlüdür — _process polling yok.
##
## Player referansı: her kat geçişinde Player yeniden oluşturulduğundan
## EventBus.run_started ve floor_cleared sinyalleri üzerinden yeniden bağlanır.
extends CanvasLayer

@onready var hp_bar:      ProgressBar = $Control/TopLeft/HPRow/HPBar
@onready var hp_label:    Label       = $Control/TopLeft/HPRow/HPLabel
@onready var xp_bar:      ProgressBar = $Control/TopLeft/XPRow/XPBar
@onready var xp_label:    Label       = $Control/TopLeft/XPRow/XPLabel
@onready var floor_label: Label       = $Control/TopRight/FloorLabel
@onready var gold_label:  Label       = $Control/TopRight/GoldLabel
@onready var weapon_icon: TextureRect = $Control/TopLeft/WeaponRow/WeaponIcon
@onready var weapon_label: Label      = $Control/TopLeft/WeaponRow/WeaponLabel
@onready var toast_label: Label        = $Control/ToastLabel

var _health_component: HealthComponent = null
var _toast_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	## ProgressBar'lara görünür renkler ver (Godot 4 varsayılanı şeffaf).
	_style_bar(hp_bar, Color("c0392b"), Color("2c1010"))
	_style_bar(xp_bar, Color("2980b9"), Color("0d1a2e"))

	## Sinyal bağlantıları
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.floor_cleared.connect(_on_floor_cleared)
	EventBus.meta_currency_changed.connect(_on_currency_changed)
	EventBus.run_started.connect(_on_run_started)
	EventBus.player_died.connect(_on_player_died)
	## Sandıktan veya level-up ekranından bir upgrade kazanıldığında kısa bir
	## bildirim göster — özellikle sandık kaynaklı kalıcı/run-içi kazanımlar
	## başka hiçbir şekilde fark edilmiyordu.
	EventBus.upgrade_selected.connect(_on_upgrade_selected)
	## Özellik 1: "Kat temizlendi" gibi genel bildirimler.
	EventBus.hud_toast.connect(_on_hud_toast)

	## Başlangıç değerleri
	_refresh_floor()
	_refresh_xp()
	gold_label.text = "* %d" % GameManager.meta_currency

	## Eğer run zaten başlamışsa hemen bağlan
	if RunManager.stats != null:
		_on_run_started()


## --- ProgressBar görsel stil ---

func _style_bar(bar: ProgressBar, fill_color: Color, bg_color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)


## --- Run / Kat bağlantısı ---

func _on_run_started() -> void:
	_refresh_xp()
	_refresh_floor()
	call_deferred("_bind_player_health")
	_bind_equipment()


func _on_floor_cleared(_floor_num: int) -> void:
	_refresh_floor()
	call_deferred("_bind_player_health")


## Player'ı bulana kadar bekleyip HealthComponent sinyaline bağlanır.
func _bind_player_health() -> void:
	## Eski bağlantıyı temizle
	if _health_component != null and is_instance_valid(_health_component):
		if _health_component.health_changed.is_connected(_on_health_changed):
			_health_component.health_changed.disconnect(_on_health_changed)
	_health_component = null

	## DungeonScene call_deferred ile eklenir — birkaç frame bekle.
	var player: Node = null
	for _attempt in 30:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
		if player != null:
			break

	if player == null:
		push_warning("HUD: Player bulunamadı, HP bar bağlanamadı.")
		return

	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc == null:
		push_warning("HUD: HealthComponent bulunamadı.")
		return

	## Çift bağlanmayı önle: _bind_player_health iki kaynaktan (run_started +
	## floor_cleared) call_deferred + await ile çağrılabildiği için aynı hc'ye
	## iki kez bağlanma yarışı oluşabiliyordu ("already connected" hatası).
	if not hc.health_changed.is_connected(_on_health_changed):
		hc.health_changed.connect(_on_health_changed)
	_health_component = hc
	_on_health_changed(hc.current_health, hc.max_health)


## Faz 8 UX: HUD'da aktif silah göstergesi. RunManager her yeni run'da
## (start_run -> _setup_run_state) tazece bir EquipmentComponent kurduğu
## için (eskisi queue_free edilir), her run_started'da yeniden bağlanırız —
## eski (artık silinen) instance'a tekrar disconnect denemesi gerekmiyor.
func _bind_equipment() -> void:
	if RunManager.equipment == null:
		return
	RunManager.equipment.equipment_changed.connect(_refresh_weapon)
	_refresh_weapon()


func _refresh_weapon() -> void:
	var weapon := RunManager.equipment.get_weapon()
	if weapon != null:
		weapon_icon.texture = weapon.icon
		weapon_label.text = weapon.display_name
		weapon_label.modulate = weapon.get_color()
	else:
		weapon_icon.texture = null
		weapon_label.text = "Silahsız"
		weapon_label.modulate = Color.WHITE


## --- Sinyal alıcıları ---

func _on_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value     = current
	hp_label.text    = "%d/%d" % [int(current), int(maximum)]


func _on_xp_gained(_amount: int) -> void:
	_refresh_xp()


func _on_level_up(_new_level: int) -> void:
	_refresh_xp()


func _on_currency_changed(new_total: int) -> void:
	gold_label.text = "* %d" % new_total


func _on_player_died() -> void:
	hp_bar.value  = 0
	hp_label.text = "0/%d" % int(hp_bar.max_value)


func _on_upgrade_selected(upgrade: UpgradeData) -> void:
	_show_toast("+ %s" % upgrade.display_name, upgrade.get_color())


func _on_hud_toast(text: String) -> void:
	_show_toast(text, Color(0.8, 1.0, 0.85))


## Kısa, kendiliğinden kaybolan bildirim (upgrade kazanımı, kat temizleme...).
func _show_toast(text: String, color: Color) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	toast_label.modulate.a = 0.0

	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_label, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(1.3)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)


## --- Yardımcılar ---

func _refresh_xp() -> void:
	xp_bar.max_value = RunManager.xp_to_next
	xp_bar.value     = RunManager.xp
	xp_label.text    = "Lv.%d" % RunManager.level


func _refresh_floor() -> void:
	floor_label.text = "Kat %d" % RunManager.current_floor

## Main — oyunun kök sahnesi. Kat içeriğini barındıracak FloorRoot'u
## RunManager'a bildirir ve run'ı başlatır.
##
## Faz 7: UpgradeScreen burada instantiate edilir.
## Faz 8: HUD, PauseMenu, DeathScreen, Minimap burada oluşturulup eklenir.
## InventoryUI Main.tscn'de doğrudan instance olarak zaten mevcut.
##
## Tüm UI sahneleri CanvasLayer olduğu için kamera/dünya koordinatlarından
## bağımsız çalışır; layer sıralaması: HUD+Minimap=5, UpgradeScreen=10,
## PauseMenu=20, DeathScreen=30.
extends Node2D

const UPGRADE_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/UpgradeScreen.tscn")
const HUD_SCENE:            PackedScene = preload("res://scenes/ui/HUD.tscn")
const PAUSE_MENU_SCENE:     PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
const DEATH_SCREEN_SCENE:   PackedScene = preload("res://scenes/ui/DeathScreen.tscn")
const MINIMAP_SCENE:        PackedScene = preload("res://scenes/ui/Minimap.tscn")
const CHEST_SCREEN_SCENE:   PackedScene = preload("res://scenes/ui/ChestScreen.tscn")
const DIALOGUE_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/DialogueScreen.tscn")

## Faz 10 (hikaye): oyun başında okunan karanlık fantezi girişi.
const STORY_TITLE := "GÜNEŞSİZ TAÇ"
const STORY_BODY := "Bir zamanlar Aethelgard krallığı, güneşin hiç batmadığı topraklarda parlardı.\nTa ki Kral, yeraltının derinliklerinde uyuyan Güneşsiz Taç'ı başına geçirene dek.\nTaç ona ölümsüzlük vaat etti — karşılığında krallığın ışığını aldı.\nGüneş söndü. Halk taşa, şövalyeler gölgeye döndü.\nSen, küllerden doğan son alevsin.\nÜç Muhafız'ın koruduğu dokuz kata in. Taç'ı kır — ya da karanlığın bir parçası ol."

@onready var floor_root: Node2D = $FloorRoot


func _ready() -> void:
	## UI katmanlarını ekle (sıra önemli: önce arka katmanlar).
	add_child(HUD_SCENE.instantiate())
	add_child(MINIMAP_SCENE.instantiate())
	add_child(UPGRADE_SCREEN_SCENE.instantiate())
	add_child(CHEST_SCREEN_SCENE.instantiate())
	add_child(DIALOGUE_SCREEN_SCENE.instantiate())
	add_child(PAUSE_MENU_SCENE.instantiate())
	add_child(DEATH_SCREEN_SCENE.instantiate())

	RunManager.set_floor_parent(floor_root)
	RunManager.start_run()

	## Oyun açılışında hikaye girişini göster (DialogueScreen duraklatır).
	EventBus.story_requested.emit(STORY_TITLE, STORY_BODY)

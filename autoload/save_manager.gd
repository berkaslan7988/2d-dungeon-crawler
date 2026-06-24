## SaveManager — meta ilerlemeyi (kalıcı para, istatistikler, açılanlar)
## diske yazar/okur. Autoload adı: SaveManager
##
## Sadece META kayıt edilir — run-içi durum (XP, level, ekipman) kaydedilmez.
## Aynı run'a devam özelliği istenseydi ayrı bir "run save" gerekir.
##
## KURAL: Daima user:// altına yaz (res:// export'ta salt-okunur).
## Windows:  %APPDATA%\Godot\app_userdata\<proje>\save.json
## Editörde: Project → Open User Data Folder
extends Node

const SAVE_PATH: String = "user://save.json"
## Format değişince eski save'leri güvenli okumak için sürüm alanı.
const SAVE_VERSION: int = 1


## Meta veriyi diske yazar. data Dictionary'sine "version" otomatik eklenir.
func save_meta(data: Dictionary) -> void:
	data["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: save dosyası açılamadı — " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Mevcut save'i okur. Dosya yoksa veya bozuksa varsayılanı döndürür.
func load_meta() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_meta()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: save dosyası okunamadı — " + SAVE_PATH)
		return _default_meta()

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: bozuk save, varsayılana düşülüyor.")
		return _default_meta()

	# Sürüm uyumsuzluğu: ileride migration buraya eklenir.
	if parsed.get("version", 0) != SAVE_VERSION:
		push_warning("SaveManager: farklı save sürümü (%d), varsayılana düşülüyor." \
				% parsed.get("version", 0))
		return _default_meta()

	return parsed


## Save dosyasını siler (debug / "yeni oyun" için).
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## Hiç save yokken veya bozuk save'de kullanılan güvenli başlangıç değerleri.
func _default_meta() -> Dictionary:
	return {
		"version":      SAVE_VERSION,
		"currency":     0,
		"total_runs":   0,
		"best_floor":   0,
		"purchased_meta_upgrades": [],
	}

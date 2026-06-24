## EventBus — proje genelinde gevşek bağlı (loose-coupled) iletişim için
## tek merkez. Autoload adı: EventBus
##
## Kullanım:
##   EventBus.enemy_died.emit(self, attacker)   # yayınla
##   EventBus.enemy_died.connect(_on_enemy_died) # dinle
##
## NOT: Tüm sinyaller TANIM gereği başka scriptlerden emit/connect edilir;
## bu dosyanın içinde kullanılmazlar. Godot'un "unused_signal" uyarısı bu
## desen için yanlış pozitiftir, bu yüzden her sinyalde bastırılır.
extends Node

# --- Dövüş ---
@warning_ignore("unused_signal")
signal enemy_died(enemy: Node, source: Node)
@warning_ignore("unused_signal")
signal player_died

# --- İlerleme (Faz 7) ---
@warning_ignore("unused_signal")
signal xp_gained(amount: int)
@warning_ignore("unused_signal")
signal player_leveled_up(new_level: int)
@warning_ignore("unused_signal")
signal upgrade_selected(upgrade: UpgradeData)

# --- Loot / envanter ---
@warning_ignore("unused_signal")
signal item_picked_up(item: Resource)
@warning_ignore("unused_signal")
signal inventory_changed

# --- Meta (Faz 7) ---
@warning_ignore("unused_signal")
signal meta_currency_changed(new_total: int)

# --- Run akışı ---
@warning_ignore("unused_signal")
signal floor_cleared(floor_number: int)
@warning_ignore("unused_signal")
signal run_started
@warning_ignore("unused_signal")
signal run_ended(victory: bool)

# --- Juice / Geri bildirim (Faz 9) ---
## Bir varlığa hasar UYGULANDIĞINDA yayınlanır (HurtboxComponent'ten).
## to_player: hasarı alan oyuncu mu (true) yoksa düşman mı (false).
@warning_ignore("unused_signal")
signal damage_dealt(amount: float, world_position: Vector2, to_player: bool, is_crit: bool)
## Kamera sarsıntısı isteği (şiddet ~ piksel). ShakeCamera2D dinler.
@warning_ignore("unused_signal")
signal screen_shake_requested(strength: float)
## Hit-stop (kısa süre Engine.time_scale düşürme). Juice autoload dinler.
@warning_ignore("unused_signal")
signal hit_stop_requested(duration: float, time_scale: float)
## İsimle SFX çalma isteği (örn. "hit", "hurt", "loot"). AudioManager dinler.
@warning_ignore("unused_signal")
signal sfx_requested(sfx_name: StringName)
## İsimle müzik çalma isteği (örn. "dungeon"). AudioManager dinler.
@warning_ignore("unused_signal")
signal music_requested(track_name: StringName)

# --- Akış / hikaye / sandık (Faz 10+) ---
## HUD'da kısa bilgi mesajı ("Kat temizlendi!" gibi).
@warning_ignore("unused_signal")
signal hud_toast(text: String)
## Sandık açıldı: içindeki eşyalar (+ varsa upgrade). ChestScreen dinler.
@warning_ignore("unused_signal")
signal chest_opened(items: Array, upgrade: UpgradeData)
## Boss odasına girildi: intro diyaloğu için. DialogueScreen dinler.
@warning_ignore("unused_signal")
signal boss_encountered(data: BossData)
## Boss yenildi: yenilgi diyaloğu (+ final ise zafer). DialogueScreen dinler.
@warning_ignore("unused_signal")
signal boss_defeated(data: BossData)
## Genel hikaye/anlatı ekranı isteği (başlık + gövde). DialogueScreen dinler.
@warning_ignore("unused_signal")
signal story_requested(title: String, body: String)

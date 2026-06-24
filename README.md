# 🗡️ Güneşsiz Taç — 2D Dungeon Crawler

> Top-down, roguelite esintili, prosedürel bir zindan sürünücüsü. **Godot 4.7 (GL Compatibility)** · **GDScript**.

Bir zamanlar güneşin hiç batmadığı **Aethelgard** krallığı, Kral'ın yeraltındaki *Güneşsiz Taç*'ı başına geçirmesiyle karanlığa gömüldü. Küllerden doğan son alev olarak, üç Muhafız'ın koruduğu dokuz kata in ve laneti kır — ya da karanlığın bir parçası ol.

---

## ✨ Özellikler

- **Prosedürel zindan üretimi** — her run farklı ama her zaman gezilebilir (flood-fill bağlanabilirlik garantisi, seed destekli).
- **Akıcı dövüş** — fareyle nişan alma, kılıç saldırısı, dash, i-frame + knockback, hit-flash.
- **6 düşman türü** — slime, hızlı yarasa, bölünen slime, menzilli büyücü, tank ve mini slime; kat ilerledikçe ölçeklenen zorluk.
- **3 boss + hikaye** — Garoth (kat 3), Myrra (kat 6), Kral Vorlak (kat 9, final). Telegraph'lı çok fazlı saldırılar, savaş öncesi/sonrası diyaloglar.
- **Loot & envanter** — 17 eşya (silah/zırh/iksir), rarity sistemi, kuşanım, hazine sandıkları, fazlalığı meta paraya çevirme.
- **İlerleme** — XP/level, level-up'ta 3 karttan upgrade seçimi (22 upgrade), kalıcı meta para + mağaza, JSON save/load.
- **Görsel & ses cila** — ekran sarsıntısı, hit-stop, partiküller, uçan hasar sayıları, SFX/müzik (AudioManager).
- **Tam UI** — HUD, minimap (fog-of-war), pause, envanter, upgrade ekranı, ölüm/zafer özeti, ana menü.

---

## 🎮 Kontroller

| Eylem | Tuş |
|-------|-----|
| Hareket | `WASD` / Yön tuşları |
| Nişan | Fare |
| Saldırı | `F` / Sol tık |
| Atılma (dash) | `Shift` |
| Etkileşim | `Q` |
| Envanter | `E` |
| Duraklat | `Esc` |

Gamepad de desteklenir (sol çubuk hareket, butonlar eylemler).

---

## 🚀 Nasıl Çalıştırılır

1. **Godot 4.7** (stable, GL Compatibility) indir: <https://godotengine.org>
2. Bu depoyu klonla veya indir.
3. Godot'ta **Import** → `project.godot` dosyasını seç → **Aç**.
4. **Play (F5)** ile çalıştır. Oyun ana menüyle, tam ekran açılır.

> **Ses dosyaları:** SFX/müzik `assets/audio/sfx/` ve `assets/audio/music/` altına beklenir (bkz. `FAZ9_SES_REHBERI.md`). Eksikse oyun sessiz çalışır, çökmez.

---

## 🗂️ Proje Yapısı

```
autoload/      Singleton'lar: EventBus, GameManager, RunManager, SaveManager, AudioManager, Juice
components/     Yeniden kullanılabilir: Health/Hitbox/Hurtbox/Stats/Inventory/Equipment, ShakeCamera
resources/      Veri sınıfları: ItemData, WeaponData, EnemyData, BossData, UpgradeData, LootTable...
data/           İçerik (.tres): düşmanlar, bosslar, eşyalar, upgrade'ler, loot tabloları
systems/        DungeonGenerator (oda + koridor + bağlanabilirlik)
scenes/
  player/       Player
  enemies/      Enemy (FSM), Boss, Projectile
  items/        Pickup, Chest
  world/        Main, DungeonScene
  ui/           HUD, Minimap, Pause, Inventory, Upgrade, Chest, Dialogue, Death, MainMenu
  fx/           DamageNumber, HitSpark, DeathPuff
assets/         Sprite, tileset, shader, (ses)
themes/         dungeon_theme.tres (karanlık UI teması)
```

**Mimari ilkeler:** veri/koddan ayrı (`Resource` + `.tres`), sinyalle gevşek bağ (`EventBus`), bileşen deseni, sabitler tek yerde (`Constants`).

---

## 🙏 Krediler

- **Motor:** [Godot Engine](https://godotengine.org) (MIT).
- **Sprite/tileset:** yer tutucu (placeholder) görseller. Nihai sanat eklenecek.
- **Ses:** kullanıcı tarafından eklenen ücretsiz kaynaklar. CC0 için [Kenney.nl](https://kenney.nl), CC-BY için ilgili sanatçılara teşekkürler (kullanılan parçalar burada listelenmeli).

> Üçüncü taraf varlık kullanırsan lisanslarını ve sanatçı adlarını bu bölüme eklemeyi unutma.

---

## 📜 Lisans

Kod **MIT Lisansı** altındadır — bkz. [LICENSE](LICENSE). Üçüncü taraf varlıkların lisansları ayrıca geçerlidir.

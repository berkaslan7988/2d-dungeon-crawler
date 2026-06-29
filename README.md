<div align="center">

# 🗡️ Güneşsiz Taç — 2D Dungeon Crawler

**Prosedürel, roguelite esintili top-down zindan sürünücüsü · Godot 4.7 · GDScript**

</div>

---

```
Bir zamanlar Aethelgard krallığı hiç batmayan bir güneşin altında parlardı —
ta ki Kral, derinlerdeki Güneşsiz Taç'ı başına geçirene dek.
```

Küllerden doğan son alevsin. Üç Muhafız'ın koruduğu dokuz kata in ve laneti kır — ya da karanlığın bir parçası ol.

---

## ✨ Özellikler

| Özellik | Detaylar |
|---------|----------|
| 🎲 **Prosedürel** | Oda+koridor üretici, seed desteği, flood-fill bağlanabilirlik garantisi |
| ⚔️ **Dövüş** | Bileşen tabanlı Hitbox/Hurtbox, fareyle nişan, dash, i-frame, geri itme, hit-flash |
| 🤖 **Düşman AI** | FSM tabanlı 6 düşman türü (menzilli, bölünen, tank) |
| 👑 **Boss & Hikaye** | 3 çok fazlı boss (3/6/9. katlar), telegraph'lı saldırı + diyaloglar |
| 🎒 **Sistemler** | Loot, envanter, ekipman, 22 upgrade, XP/seviye, meta ilerleme, JSON kayıt |
| ✨ **Juice & UI** | Ekran sarsıntısı, hit-stop, partikül, hasar sayıları, shader, havuzlama, tam UI |

## 🎮 Kontroller

| Eylem | Tuş |
|-------|-----|
| Hareket | `WASD` · Yön tuşları |
| Nişan | Fare |
| Saldırı | `F` · Sol tık |
| Atılma | `Shift` |
| Etkileşim | `Q` |
| Envanter | `E` |
| Duraklat | `Esc` |

Gamepad desteklenir.

## 🚀 Çalıştırma

1. **Godot 4.7** (GL Compatibility) indir: <https://godotengine.org>
2. Bu depoyu klonla/indir.
3. Godot'ta **İçe Aktar** → `project.godot` seç → **Aç**.
4. **Oynat (F5)** ile çalıştır.

> Sesler `assets/audio/` altında (bkz. `FAZ9_SES_REHBERI.md`). Eksik dosya varsa oyun sessiz çalışır, çökmez.

## 🧱 Mimari

Veri/koddan ayrık (`Resource` + `.tres`), sinyalle gevşek bağ (`EventBus`), yeniden kullanılabilir bileşenler, tek-kaynak sabitler.

```
autoload/    EventBus · GameManager · RunManager · SaveManager · AudioManager · Juice
components/  Health · Hitbox · Hurtbox · Stats · Inventory · Equipment · ShakeCamera
resources/   ItemData · WeaponData · EnemyData · BossData · UpgradeData · LootTable
systems/     DungeonGenerator (rooms + corridors + connectivity)
scenes/      player · enemies (Enemy/Boss/Projectile) · items · world · ui · fx
data/        enemies · bosses · items · upgrades · loot_tables  (.tres content)
```

## 🙏 Krediler

- **Motor:** [Godot](https://godotengine.org) (MIT)
- **Görseller:** yer tutucu görseller
- **Ses:** ücretsiz CC0 kaynaklar ([Kenney.nl](https://kenney.nl)) + atıflı CC-BY parçalar

> Üçüncü taraf varlıkları ve lisanslarını buraya ekle.

## 📜 Lisans

Kod **MIT** altında — bkz. [LICENSE](LICENSE). Üçüncü taraf varlıklar kendi lisanslarındadır.

<div align="center">

*"Laneti kır, ya da karanlığın bir parçası ol."*

</div>

---
---

<div align="center">

# 🗡️ Güneşsiz Taç — 2D Dungeon Crawler

**Procedural roguelite dungeon crawler · Godot 4.7 · GDScript**

</div>

---

```
Aethelgard once shone under a sun that never set —
until the King wore the Sunless Crown buried in the deep.
```

You are the last ember born from the ashes. Descend the nine floors guarded by three Wardens and break the curse — or become part of the dark.

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🎲 **Procedural** | Room+corridor generator, seed support, flood-fill connectivity guarantee |
| ⚔️ **Combat** | Component-based Hitbox/Hurtbox, mouse-aim, dash, i-frames, knockback, hit-flash |
| 🤖 **Enemy AI** | FSM (idle/patrol/chase/attack), 6 types incl. ranged, splitting, tank |
| 👑 **Bosses & Story** | 3 multi-phase bosses (floors 3/6/9), telegraphed attacks, pre/post-fight dialogue |
| 🎒 **Systems** | Loot, inventory, equipment, 22 upgrades, XP/level, meta progression, JSON save |
| ✨ **Juice & UI** | Screen shake, hit-stop, particles, damage numbers, shaders, object pooling, full menu/HUD/minimap |

## 🎮 Controls

| Action | Key |
|--------|-----|
| Move | `WASD` · Arrows |
| Aim | Mouse |
| Attack | `F` · Left click |
| Dash | `Shift` |
| Interact | `Q` |
| Inventory | `E` |
| Pause | `Esc` |

Gamepad supported.

## 🚀 Run

1. Get **Godot 4.7** (GL Compatibility): <https://godotengine.org>
2. Clone/download this repo.
3. In Godot: **Import** → select `project.godot` → **Open**.
4. Press **Play (F5)**.

> Audio lives in `assets/audio/` (see `FAZ9_SES_REHBERI.md`). Missing files = silent, no crash.

## 🧱 Architecture

Data-driven (`Resource` + `.tres`), signal-based loose coupling (`EventBus`), reusable components, single-source constants.

```
autoload/    EventBus · GameManager · RunManager · SaveManager · AudioManager · Juice
components/  Health · Hitbox · Hurtbox · Stats · Inventory · Equipment · ShakeCamera
resources/   ItemData · WeaponData · EnemyData · BossData · UpgradeData · LootTable
systems/     DungeonGenerator (rooms + corridors + connectivity)
scenes/      player · enemies (Enemy/Boss/Projectile) · items · world · ui · fx
data/        enemies · bosses · items · upgrades · loot_tables  (.tres content)
```

## 🙏 Credits

- **Engine:** [Godot](https://godotengine.org) (MIT)
- **Sprites/tiles:** placeholder art
- **Audio:** free CC0 sources ([Kenney.nl](https://kenney.nl)) + attributed CC-BY tracks

> List any third-party assets and their licenses here.

## 📜 License

Code under **MIT** — see [LICENSE](LICENSE). Third-party assets keep their own licenses.

<div align="center">

*"Break the curse, or become part of the dark."*

</div>

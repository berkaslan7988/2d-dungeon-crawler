<div align="center">

# 🗡️ Güneşsiz Taç — 2D Dungeon Crawler

**Procedural roguelite dungeon crawler · Godot 4.7 · GDScript**
*Prosedürel, roguelite esintili top-down zindan sürünücüsü*

</div>

---

```
Aethelgard once shone under a sun that never set —
until the King wore the Sunless Crown buried in the deep.

Bir zamanlar Aethelgard krallığı hiç batmayan bir güneşin altında parlardı —
ta ki Kral, derinlerdeki Güneşsiz Taç'ı başına geçirene dek.
```

You are the last ember born from the ashes. Descend the nine floors guarded by three Wardens and break the curse — or become part of the dark.
Küllerden doğan son alevsin. Üç Muhafız'ın koruduğu dokuz kata in ve laneti kır — ya da karanlığın bir parçası ol.

---

## ✨ Features / Özellikler

| Feature / Özellik | Details / Detaylar |
|-------------------|--------------------|
| 🎲 **Procedural / Prosedürel** | Room+corridor generator, seed support, **flood-fill connectivity guarantee** / Oda+koridor üretici, seed desteği, flood-fill bağlanabilirlik garantisi |
| ⚔️ **Combat / Dövüş** | Component-based Hitbox/Hurtbox, mouse-aim, dash, i-frames, knockback, hit-flash / Bileşen tabanlı dövüş, fareyle nişan, dash, i-frame |
| 🤖 **Enemy AI / Düşman AI** | FSM (idle/patrol/chase/attack), 6 types incl. ranged, splitting, tank / FSM tabanlı 6 düşman türü (menzilli, bölünen, tank) |
| 👑 **Bosses & Story / Boss & Hikaye** | 3 multi-phase bosses (floors 3/6/9), telegraphed attacks, pre/post-fight dialogue / 3 çok fazlı boss, telegraph'lı saldırı + diyaloglar |
| 🎒 **Systems / Sistemler** | Loot, inventory, equipment, 22 upgrades, XP/level, meta progression, JSON save / Loot, envanter, ekipman, 22 upgrade, meta ilerleme, save |
| ✨ **Juice & UI** | Screen shake, hit-stop, particles, damage numbers, shaders, object pooling, full menu/HUD/minimap / Sarsıntı, hit-stop, partikül, shader, havuzlama, tam UI |

---

## 🎮 Controls / Kontroller

| Action / Eylem | Key / Tuş |
|----------------|-----------|
| Move / Hareket | `WASD` · Arrows / Yön tuşları |
| Aim / Nişan | Mouse / Fare |
| Attack / Saldırı | `F` · Left click / Sol tık |
| Dash / Atılma | `Shift` |
| Interact / Etkileşim | `Q` |
| Inventory / Envanter | `E` |
| Pause / Duraklat | `Esc` |

Gamepad supported / Gamepad desteklenir.

---

## 🚀 Run / Çalıştırma

1. Get **Godot 4.7** (GL Compatibility): <https://godotengine.org>
2. Clone/download this repo · Bu depoyu klonla/indir.
3. In Godot: **Import** → select `project.godot` → **Open** / Godot'ta İçe Aktar → `project.godot` seç → Aç.
4. Press **Play (F5)** / **Oyun (F5)** ile çalıştır.

> Audio lives in `assets/audio/` (see `FAZ9_SES_REHBERI.md`). Missing files = silent, no crash.
> Sesler `assets/audio/` altında; eksikse oyun sessiz çalışır, çökmez.

---

## 🧱 Architecture / Mimari

Data-driven (`Resource` + `.tres`), signal-based loose coupling (`EventBus`), reusable components, single-source constants.
Veri/koddan ayrık (`Resource` + `.tres`), sinyalle gevşek bağ (`EventBus`), yeniden kullanılabilir bileşenler, tek-kaynak sabitler.

```
autoload/    EventBus · GameManager · RunManager · SaveManager · AudioManager · Juice
components/   Health · Hitbox · Hurtbox · Stats · Inventory · Equipment · ShakeCamera
resources/    ItemData · WeaponData · EnemyData · BossData · UpgradeData · LootTable
systems/      DungeonGenerator (rooms + corridors + connectivity)
scenes/       player · enemies (Enemy/Boss/Projectile) · items · world · ui · fx
data/         enemies · bosses · items · upgrades · loot_tables  (.tres content)
```

---

## 🙏 Credits / Krediler

- **Engine / Motor:** [Godot](https://godotengine.org) (MIT)
- **Sprites/tiles:** placeholder art / yer tutucu görseller
- **Audio / Ses:** free CC0 sources ([Kenney.nl](https://kenney.nl)) + attributed CC-BY tracks / ücretsiz CC0 + atıflı CC-BY parçalar

> List any third-party assets and their licenses here. / Üçüncü taraf varlıkları ve lisanslarını buraya ekle.

---

## 📜 License / Lisans

Code under **MIT** — see [LICENSE](LICENSE). Third-party assets keep their own licenses.
Kod **MIT** altında — bkz. [LICENSE](LICENSE). Üçüncü taraf varlıklar kendi lisanslarındadır.

<div align="center">

*"Break the curse, or become part of the dark." / "Laneti kır, ya da karanlığın bir parçası ol."*

</div>

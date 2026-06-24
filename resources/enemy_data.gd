## EnemyData — düşman türünü tanımlayan veri kaynağı. Aynı Enemy.tscn,
## farklı bir EnemyData ile tamamen farklı bir düşman gibi davranır
## (istatistikler, görsel, algı/saldırı menzilleri, drop tablosu).
##
## Faz 10: AttackType (melee/ranged), bölünme (split), görsel tint ve
## menzilli düşmanlar için "kaçış mesafesi" (kiting) alanları eklendi.
class_name EnemyData
extends Resource

## Faz 10: yakın dövüş mü menzilli mi? RANGED ise saldırıda mermi atar.
enum AttackType { MELEE, RANGED }

@export_group("Genel")
@export var display_name: String = "Enemy"
@export var sprite_frames: SpriteFrames
## Faz 10: aynı placeholder sprite'ı renklendirerek tür ayırt etmek için.
@export var sprite_tint: Color = Color.WHITE
## Faz 10: sprite ölçeği (ör. küçük yarasa < slime < tank).
@export var sprite_scale: float = 1.0

@export_group("İstatistikler")
@export var max_health: float = 30.0
@export var move_speed: float = 40.0
@export var damage: float = 8.0
@export var knockback: float = 100.0

@export_group("Algı & Saldırı")
@export var attack_type: AttackType = AttackType.MELEE
@export var detection_range: float = 70.0
@export var attack_range: float = 14.0
@export var attack_cooldown: float = 1.0
@export var attack_active_time: float = 0.15
## Faz 10 (menzilli): saldırıda atılan mermi sahnesi + hızı. attack_type
## RANGED ise kullanılır. damage mermi hasarı olarak geçer.
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 90.0
## Faz 10 (menzilli/kiting): oyuncu bu mesafeden yakınsa düşman geri çekilir
## (0 = kaçma, hep yaklaş). Okçu/büyücü için ~50-60 idealdir.
@export var flee_distance: float = 0.0

@export_group("Devriye")
@export var patrol_radius: float = 40.0
@export var patrol_wait_time: float = 1.5

@export_group("Bölünme (Faz 10)")
## Ölünce bu türden split_count adet spawn eder (ör. slime → mini slime).
## Sonsuz bölünmeyi önlemek için mini'nin split_into'su null olmalı.
@export var split_into: EnemyData
@export var split_count: int = 0

@export_group("Ödül")
@export var xp_reward: int = 10
@export var loot_table: LootTable

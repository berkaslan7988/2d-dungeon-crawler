## Constants — katman numaraları, grup isimleri, sahne yolları gibi
## "magic number" olmaması gereken sabitler tek yerde.
## Autoload adı: Constants
extends Node

# --- Collision Layer planı (Project Settings → Layer Names → 2D Physics ile eşleşir) ---
# Layer index'leri (1-9), Project Settings'teki sırayla aynı.
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_PLAYER_HURTBOX: int = 3
const LAYER_ENEMY: int = 4
const LAYER_ENEMY_HURTBOX: int = 5
const LAYER_PLAYER_HITBOX: int = 6
const LAYER_ENEMY_HITBOX: int = 7
const LAYER_PICKUPS: int = 8
const LAYER_PROJECTILES: int = 9

# Aynı katmanların bitmask değerleri (collision_layer / collision_mask script'te
# bit değeri ister; 1 << (index - 1)).
const MASK_WORLD: int = 1 << (LAYER_WORLD - 1)
const MASK_PLAYER: int = 1 << (LAYER_PLAYER - 1)
const MASK_PLAYER_HURTBOX: int = 1 << (LAYER_PLAYER_HURTBOX - 1)
const MASK_ENEMY: int = 1 << (LAYER_ENEMY - 1)
const MASK_ENEMY_HURTBOX: int = 1 << (LAYER_ENEMY_HURTBOX - 1)
const MASK_PLAYER_HITBOX: int = 1 << (LAYER_PLAYER_HITBOX - 1)
const MASK_ENEMY_HITBOX: int = 1 << (LAYER_ENEMY_HITBOX - 1)
const MASK_PICKUPS: int = 1 << (LAYER_PICKUPS - 1)
const MASK_PROJECTILES: int = 1 << (LAYER_PROJECTILES - 1)

# --- Grup isimleri ---
const GROUP_PLAYER: String = "player"
const GROUP_ENEMIES: String = "enemies"

# --- Sahne yolları ---
const SCENE_MAIN: String = "res://scenes/world/Main.tscn"
const SCENE_PLAYER: String = "res://scenes/player/Player.tscn"

# --- Tile boyutu (Faz 2'de sabitlenecek, baştan tutarlı tutmak için burada) ---
const TILE_SIZE: int = 16

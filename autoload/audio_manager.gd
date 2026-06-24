## AudioManager — Faz 9: merkezi ses yöneticisi. Autoload adı: AudioManager
##
## TASARIM:
## - Master / Music / SFX bus'ları çalışma anında (AudioServer) kurulur —
##   ayrı bir bus layout .tres dosyasına gerek yok.
## - SFX ve müzik dosyaları İSİMLE, sabit yollardan yüklenir
##   (res://assets/audio/sfx/<isim>.wav|ogg, .../music/<isim>.ogg|wav).
##   Dosya yoksa o ses sessizce atlanır (oyun çökmez, bir kez uyarı basar).
##   => Gerçek sesleri indirip doğru isimle bu klasörlere koyman yeterli;
##      kod değiştirmeye gerek yok. Beklenen isimler için SFX_FILES / MUSIC_FILES.
## - play_sfx() bir AudioStreamPlayer HAVUZU kullanır (her ses için yeni node
##   yaratıp sızdırmaz — roadmap'in "node patlaması" uyarısına uygun).
## - EventBus oyun olaylarına (vuruş, ölüm, loot, level-up...) otomatik bağlanır;
##   böylece sistemler ses kodu bilmeden ses çıkar.
extends Node

## Bus isimleri
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

## Aynı anda çalabilecek azami SFX sayısı (havuz boyutu).
const SFX_POOL_SIZE := 12

## Beklenen SFX dosyaları (uzantısız temel yol). Hangisi varsa o yüklenir.
const AUDIO_SFX_DIR := "res://assets/audio/sfx/"
const AUDIO_MUSIC_DIR := "res://assets/audio/music/"
const SFX_NAMES: Array[StringName] = [
	&"hit",         ## oyuncu bir düşmana vurdu
	&"hurt",        ## oyuncu hasar aldı
	&"enemy_death", ## düşman öldü
	&"player_death",## oyuncu öldü
	&"loot",        ## eşya toplandı
	&"level_up",    ## seviye atlandı
	&"chest",       ## sandık açıldı
	&"ui_click",    ## buton / UI tık
	&"dash",        ## atılma
]
const MUSIC_NAMES: Array[StringName] = [
	&"dungeon",     ## ana zindan ambiyansı (loop)
]
## Yüklemede denenecek uzantılar (sıra önemli: ilk bulunan kullanılır).
const TRY_EXTENSIONS: Array[String] = [".ogg", ".wav"]

var _sfx_streams: Dictionary = {}    ## name(StringName) -> AudioStream
var _music_streams: Dictionary = {}  ## name(StringName) -> AudioStream
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
var _music_player: AudioStreamPlayer = null
var _current_music: StringName = &""
var _warned_missing: Dictionary = {}  ## tekrarlı uyarıyı önlemek için


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  ## duraklamada da ses kesilmesin
	_setup_buses()
	_setup_pool()
	_load_streams()
	_connect_events()


## --- Kurulum ---

func _setup_buses() -> void:
	## Master her zaman 0. Music ve SFX yoksa ekle, varsa dokunma.
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		AudioServer.add_bus()
		var music_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_idx, BUS_MUSIC)
		AudioServer.set_bus_send(music_idx, BUS_MASTER)
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		var sfx_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_idx, BUS_SFX)
		AudioServer.set_bus_send(sfx_idx, BUS_MASTER)


func _setup_pool() -> void:
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)


func _load_streams() -> void:
	for sfx_name in SFX_NAMES:
		var stream := _try_load(AUDIO_SFX_DIR + String(sfx_name))
		if stream != null:
			_sfx_streams[sfx_name] = stream
	for music_name in MUSIC_NAMES:
		var stream := _try_load(AUDIO_MUSIC_DIR + String(music_name))
		if stream != null:
			_music_streams[music_name] = stream


## Verilen uzantısız yola TRY_EXTENSIONS sırasıyla bakar, ilk bulduğunu yükler.
func _try_load(base_path: String) -> AudioStream:
	for ext in TRY_EXTENSIONS:
		var path := base_path + ext
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is AudioStream:
				return res as AudioStream
	return null


func _connect_events() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.run_started.connect(_on_run_started)
	## Doğrudan isimle çalma istekleri (UI tık, sandık, dash vb.)
	EventBus.sfx_requested.connect(play_sfx)
	EventBus.music_requested.connect(play_music)


## --- Genel API ---

## İsimle bir SFX çalar (havuzdan boş/eski bir player kullanır).
func play_sfx(sfx_name: StringName, pitch_variation: float = 0.06) -> void:
	if not _sfx_streams.has(sfx_name):
		_warn_missing(sfx_name)
		return
	var player := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	player.stream = _sfx_streams[sfx_name]
	## Hafif rastgele pitch — aynı ses üst üste çalınca tekdüze olmasın.
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## İsimle müzik çalar (zaten çalan aynı parçaysa yeniden başlatmaz). Loop'lar.
func play_music(track_name: StringName) -> void:
	if _current_music == track_name and _music_player.playing:
		return
	if not _music_streams.has(track_name):
		_warn_missing(track_name)
		return
	_current_music = track_name
	_music_player.stream = _music_streams[track_name]
	_music_player.play()


func stop_music() -> void:
	_current_music = &""
	_music_player.stop()


## --- Ses seviyesi (ileride Ayarlar menüsü için hazır) ---

## linear 0.0–1.0 → dB. 0 = sessiz (-80 dB).
func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var db := -80.0 if linear <= 0.001 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(idx, db)


func set_master_volume(linear: float) -> void:
	set_bus_volume(BUS_MASTER, linear)


func set_music_volume(linear: float) -> void:
	set_bus_volume(BUS_MUSIC, linear)


func set_sfx_volume(linear: float) -> void:
	set_bus_volume(BUS_SFX, linear)


## --- EventBus alıcıları ---

func _on_damage_dealt(_amount: float, _world_position: Vector2, to_player: bool, _is_crit: bool) -> void:
	play_sfx(&"hurt" if to_player else &"hit")


func _on_enemy_died(_enemy: Node, _source: Node) -> void:
	play_sfx(&"enemy_death")


func _on_player_died() -> void:
	play_sfx(&"player_death")


func _on_item_picked_up(_item: Resource) -> void:
	play_sfx(&"loot")


func _on_level_up(_new_level: int) -> void:
	play_sfx(&"level_up")


func _on_run_started() -> void:
	## Zindan müziğini başlat (dosya yoksa sessizce atlanır).
	play_music(&"dungeon")


func _on_music_finished() -> void:
	## Müzik bittiğinde döngüye al (stream loop'lu değilse bile sürer).
	if _current_music != &"" and _music_streams.has(_current_music):
		_music_player.play()


## --- Yardımcı ---

func _warn_missing(missing_name: StringName) -> void:
	if _warned_missing.has(missing_name):
		return
	_warned_missing[missing_name] = true
	push_warning("AudioManager: '%s' ses dosyası yok (assets/audio/...). Sessiz geçiliyor." % missing_name)

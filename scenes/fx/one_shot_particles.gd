## OneShotParticles — Faz 9: spawn edilip bir kez patlayan, bitince kendini
## temizleyen CPUParticles2D. HitSpark / DeathPuff / LootSparkle gibi kısa
## efektler bunu kullanır (roadmap: "node patlaması olmasın" — bitince free).
extends CPUParticles2D


func _ready() -> void:
	one_shot = true
	emitting = true
	finished.connect(queue_free)

// flash.gdshader — Faz 9: vurulan sprite'ı kısa süre beyaza boyar.
// flash_amount 0..1 arası tween'lenir (enemy.gd / player.gd vuruşta 1→0).
// Dokunun alfa'sı korunur, sadece görünür pikseller beyazlatılır.
shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 mixed = mix(tex.rgb, flash_color.rgb, flash_amount);
	// Gelen COLOR (node modulate'i: ölüm fade'i, i-frame alfa vb.) ile çarp —
	// aksi halde modulate yok sayılır ve sprite kaybolma animasyonu çalışmaz.
	COLOR = vec4(mixed, tex.a) * COLOR;
}

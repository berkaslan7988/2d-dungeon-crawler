// Tiles store a shade (0–4) instead of a colour: red = shade * 32 + 16 and
// alpha = 200; green picks the ramp (0 = stone, 1 = wall tops). Light shifts
// the shade along the ramp, cold slate in the dark to warm brown next to the
// flame (wall tops stay cool), dithered between levels. Opaque pixels are
// literal colours (void, the ember glow in the stairs).
shader_type canvas_item;
render_mode unshaded;

#include "res://assets/shaders/light.gdshaderinc"

uniform sampler2D ramp : filter_nearest;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 wp = floor(world_pos);
	if (!sc_seen(wp)) {
		COLOR = vec4(0.0235, 0.0235, 0.0353, 1.0);
	} else if (c.a > 0.7 && c.a < 0.85) {
		float shade = floor(c.r * 255.0 / 32.0);
		float level = clamp(floor(sc_light_at(wp + 0.5) + sc_bayer(wp)), 0.0, 5.0);
		int idx = int(clamp(shade + level - 1.0, 0.0, 7.0));
		int row = c.g > 0.5 ? 1 : 0;
		COLOR = vec4(texelFetch(ramp, ivec2(idx, row), 0).rgb, 1.0);
	} else {
		COLOR = vec4(c.rgb, c.a > 0.01 ? 1.0 : 0.0);
	}
}

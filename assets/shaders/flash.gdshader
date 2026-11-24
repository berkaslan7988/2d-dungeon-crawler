// Lit sprite + hit flash. Every actor and prop uses this.
// The light level at the sprite's feet picks one of four looks: full colour,
// two darker steps, or a soot silhouette. Pixels exported with alpha 240 are
// emissive (eyes, flames, orbs) and stay bright in the dark.
shader_type canvas_item;
render_mode unshaded;

#include "res://assets/shaders/light.gdshaderinc"

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
// The player carries the light, so it is always fully lit.
uniform float light_bias = 0.0;
uniform float feet_offset = 6.0;
// Props vanish on tiles nobody has seen; actors there become silhouettes.
uniform bool hide_in_fog = false;

varying vec2 origin;

void vertex() {
	origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		discard;
	}
	vec2 feet = origin + vec2(0.0, feet_offset);
	bool seen = sc_seen(floor(feet));
	if (!seen && hide_in_fog) {
		discard;
	}
	bool emissive = tex.a > 0.9 && tex.a < 0.99;
	float level = sc_light_at(feet) + light_bias;
	vec3 col = tex.rgb;
	if (!emissive) {
		if (!seen || level < 0.9) {
			col = vec3(0.055, 0.059, 0.082);
		} else if (level < 2.0) {
			col *= vec3(0.52, 0.53, 0.6);
		} else if (level < 3.0) {
			col *= vec3(0.76, 0.76, 0.8);
		}
	}
	col = mix(col, flash_color.rgb, flash_amount);
	COLOR = vec4(col * COLOR.rgb, COLOR.a);
}

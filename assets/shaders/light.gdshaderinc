// Sunless Crown light model, shared by the tile and sprite shaders.
// LightManager writes up to 16 lights into sc_lights (x, y, radius, intensity)
// every frame, and the explored-tile mask into sc_fog.

global uniform sampler2D sc_lights : filter_nearest;
global uniform int sc_light_count;
global uniform sampler2D sc_fog : filter_nearest;
global uniform vec4 sc_fog_rect;

const float SC_BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
                                     3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

// Continuous light level (0 = dark, 5 = right next to the ember).
float sc_light_at(vec2 p) {
	float v = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= sc_light_count) {
			break;
		}
		vec4 l = texelFetch(sc_lights, ivec2(i, 0), 0);
		float d = distance(p, l.xy);
		if (d < l.z) {
			v += l.w * pow(1.0 - d / l.z, 1.35);
		}
	}
	return v;
}

// Ordered-dither threshold for a world pixel, in (0, 1).
float sc_bayer(vec2 world_pixel) {
	int i = int(mod(world_pixel.x, 4.0)) + int(mod(world_pixel.y, 4.0)) * 4;
	return (SC_BAYER[i] + 0.5) / 16.0;
}

bool sc_seen(vec2 world_pixel) {
	vec2 uv = (world_pixel + 0.5 - sc_fog_rect.xy) / sc_fog_rect.zw;
	return texture(sc_fog, uv).r > 0.5;
}

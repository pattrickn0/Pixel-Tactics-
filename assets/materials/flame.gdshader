shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque, shadows_disabled;
// Chama PROVISÓRIA dos braseiros (spec 012, Fase 1): gota recortada com tremor por TIME e cor
// do fogo da paleta. Emissiva (passa do limiar do glow). O flipbook da A08 entra na Fase 3.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 color_edge : source_color = vec4(0.722, 0.314, 0.110, 1.0);
uniform vec4 color_mid : source_color = vec4(0.890, 0.565, 0.255, 1.0);
uniform vec4 color_core : source_color = vec4(1.0, 0.949, 0.753, 1.0);
uniform float energy = 2.2;
// Quadros por segundo do tremor.
uniform float flicker_fps = 8.0;

void fragment() {
	float frame = floor(TIME * flicker_fps);
	vec2 uv = UV;
	float wob = (sn_noise2(vec2(uv.y * 3.0, frame * 1.7)) - 0.5) * 0.18 * (1.0 - uv.y);
	vec2 d = vec2((uv.x - 0.5 - wob) * 2.0, uv.y);
	// Gota: larga embaixo (v = 1), ponta em cima (v = 0).
	float width = pow(clamp(uv.y, 0.0, 1.0), 0.7) * (0.85 + 0.15 * sn_noise2(vec2(frame, 3.0)));
	float m = width - abs(d.x);
	float heat = clamp(m / max(width, 0.001), 0.0, 1.0) * smoothstep(0.0, 0.6, uv.y);
	vec3 c = mix(color_edge.rgb, color_mid.rgb, smoothstep(0.0, 0.35, heat));
	c = mix(c, color_core.rgb, smoothstep(0.4, 0.85, heat));
	ALBEDO = c * energy;
	ALPHA = m > 0.0 ? 1.0 : 0.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}

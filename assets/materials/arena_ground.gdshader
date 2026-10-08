shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled, blend_mix, depth_draw_opaque;
// Decalque PROVISÓRIO da arena (spec 012, Fase 1): mancha de terra alaranjada com borda irregular e
// ilhas de grama, e o círculo de pedra quebrado no meio. Tudo plano (a arena continua sem obstáculo).
// UV = posição no mundo (x, z) em unidades. Os decalques pintados da A08 entram na Fase 2.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 dirt_dark : source_color = vec4(0.494, 0.353, 0.173, 1.0);
uniform vec4 dirt_rim : source_color = vec4(0.635, 0.416, 0.212, 1.0);
uniform vec4 dirt : source_color = vec4(0.784, 0.565, 0.275, 1.0);
uniform vec4 dirt_light : source_color = vec4(0.867, 0.690, 0.416, 1.0);
uniform vec4 stone : source_color = vec4(0.733, 0.639, 0.400, 1.0);
uniform vec4 stone_light : source_color = vec4(0.839, 0.733, 0.553, 1.0);
// Mancha: centro e meios-eixos (unidades).
uniform vec2 dirt_center = vec2(0.5, -1.0);
uniform vec2 dirt_half = vec2(7.25, 5.5);
// Círculo de pedra: centro, raio de dentro e de fora.
uniform vec2 ring_center = vec2(0.4, -0.9);
uniform float ring_inner = 2.05;
uniform float ring_outer = 2.7;

void fragment() {
	vec2 p = UV;
	vec2 d = (p - dirt_center) / dirt_half;
	float ang = atan(d.y, d.x);
	// Borda irregular com braços (seed fixa), mais ilhas de grama perto da borda.
	float warp = (sn_fbm2(p * 0.35 + 4.0) - 0.5) * 0.55 + 0.08 * sin(ang * 3.0 + 1.3) + 0.06 * sin(ang * 5.0 + 0.4);
	float r = length(d) - warp;
	float islands = sn_fbm2(p * 0.9 + 21.0);
	float inside = 1.0 - r;
	float mask = smoothstep(0.0, 0.04, inside) * (1.0 - smoothstep(0.62, 0.7, islands) * smoothstep(0.35, 0.05, inside));
	float frayed = sn_noise2(p * 4.5);
	mask *= step(0.5, mask + (frayed - 0.5) * 0.4 * smoothstep(0.12, 0.0, inside) + 0.25);
	vec3 c = mix(dirt_rim.rgb, dirt.rgb, smoothstep(0.02, 0.22, inside));
	c = mix(c, dirt_light.rgb, smoothstep(0.55, 0.78, sn_fbm2(p * 0.45 + 9.0)) * 0.7);
	c = mix(c, dirt_dark.rgb, smoothstep(0.08, 0.0, inside) * 0.5);
	// Pedrinhas (pontos escuros e claros esparsos, de 0,1 a 0,2).
	float peb = sn_noise2(p * 5.0 + 2.0);
	c = mix(c, dirt_dark.rgb, smoothstep(0.86, 0.9, peb) * 0.7);
	c = mix(c, dirt_light.rgb * 1.08, smoothstep(0.88, 0.92, sn_noise2(p * 4.0 + 40.0)) * 0.8);
	// Círculo: sulco escuro, anel de pedras com falhas e disco de dentro mais claro.
	vec2 rc = p - ring_center;
	float rr = length(rc);
	float ra = atan(rc.y, rc.x);
	float seg = ra / 6.2831853 * 13.0;
	float stone_id = floor(seg);
	float gap = abs(fract(seg) - 0.5);
	float broken = step(0.8, sn_hash2(vec2(stone_id, 3.0)));
	float in_ring = step(ring_inner, rr) * step(rr, ring_outer);
	float is_stone = in_ring * step(gap, 0.42) * (1.0 - broken);
	c = mix(c, dirt_dark.rgb, smoothstep(ring_outer + 0.35, ring_outer, rr) * step(ring_outer, rr) * 0.55);
	c = mix(c, dirt_light.rgb * 1.04, smoothstep(ring_inner, ring_inner - 0.2, rr) * 0.6);
	vec3 st = mix(stone.rgb, stone_light.rgb, sn_noise2(p * 3.0 + stone_id) * 0.8);
	st *= 1.0 - smoothstep(0.32, 0.42, gap) * 0.35;
	c = mix(c, st, is_stone);
	float a = max(mask, is_stone);
	ALBEDO = c;
	ALPHA = a;
	ROUGHNESS = 1.0;
}

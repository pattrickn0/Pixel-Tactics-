shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// Chão de grama PROVISÓRIO (spec 012, Fase 1): manchas grandes de 3 a 4 verdes da paleta por ruído de
// mundo (seed fixa) e pinceladas curtas, sem grão por pixel. Canal g da cor do vértice = sombra de
// contato (pé do muro). As gramas pintadas da A08 (grass_a/b + máscara) entram na Fase 2.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 grass_dark : source_color = vec4(0.247, 0.373, 0.133, 1.0);
uniform vec4 grass_mid : source_color = vec4(0.369, 0.518, 0.141, 1.0);
uniform vec4 grass_light : source_color = vec4(0.498, 0.635, 0.173, 1.0);
uniform vec4 grass_sun : source_color = vec4(0.659, 0.769, 0.278, 1.0);
uniform float patch_scale = 0.11;
uniform float stroke_scale = 2.4;
uniform float stroke_amount = 0.07;
uniform float vertex_ao = 1.0;
// Desloca o ruído (dentro e fora do anel ficam com manchas diferentes).
uniform vec2 offset = vec2(0.0, 0.0);

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_world.xz + offset;
	float big = sn_fbm2(p * patch_scale);
	float mid = sn_fbm2(p * patch_scale * 3.1 + 7.0);
	float v = big * 0.7 + mid * 0.3;
	vec3 c = mix(grass_dark.rgb, grass_mid.rgb, smoothstep(0.18, 0.42, v));
	c = mix(c, grass_light.rgb, smoothstep(0.42, 0.62, v));
	c = mix(c, grass_sun.rgb, smoothstep(0.66, 0.85, v) * 0.8);
	// Pinceladas curtas: ruído esticado numa direção que muda devagar.
	float ang = sn_noise2(p * 0.2 + 3.0) * 6.2831;
	vec2 dir = vec2(cos(ang), sin(ang));
	vec2 q = vec2(dot(p, dir), dot(p, vec2(-dir.y, dir.x))) * stroke_scale;
	float stroke = sn_noise2(vec2(q.x * 0.5, q.y * 2.5));
	c *= 1.0 + (stroke - 0.5) * 2.0 * stroke_amount;
	c *= mix(1.0, COLOR.g, vertex_ao);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}

shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// Material PROVISÓRIO do cenário pintado (spec 012, Fase 1). A arte da A08 entra na Fase 2.
// Cor = gradiente color_low -> color_high pelo canal r da cor do vértice (0 embaixo, 1 em cima) ou
// pela altura no mundo; manchas grandes de valor por ruído de mundo (seed fixa); pinceladas largas;
// topo (normal para cima) puxado para top_color (musgo/grama). Canal g da cor = sombra de contato.
// Filtro linear, sem textura: nada de pixel.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 color_low : source_color = vec4(0.30, 0.30, 0.30, 1.0);
uniform vec4 color_high : source_color = vec4(0.70, 0.70, 0.70, 1.0);
// Manchas grandes (cor e força) e pinceladas (força e escala).
uniform vec4 color_patch : source_color = vec4(0.50, 0.50, 0.50, 1.0);
uniform float patch_scale = 0.3;
uniform float patch_amount = 0.3;
uniform float stroke_scale = 2.0;
uniform float stroke_amount = 0.06;
// Topo: musgo/grama nas faces viradas para cima.
uniform vec4 top_color : source_color = vec4(0.45, 0.58, 0.20, 1.0);
uniform float top_amount = 0.0;
uniform float top_sharpness = 3.0;
// Gradiente pela altura no mundo (penhasco: escurece e esfria para baixo).
uniform bool world_gradient = false;
uniform vec2 world_gradient_range = vec2(-20.0, 0.0);
uniform float vertex_ao = 1.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
// Dither de oclusão (OcclusionDither entrega cam_pos e arena_rect).
uniform bool dither_on = false;
uniform vec3 cam_pos = vec3(0.0, -1000.0, 0.0);
uniform vec4 arena_rect = vec4(-10.0, -9.0, 10.0, 9.0);
uniform float dither_density = 0.6;
uniform float dither_margin = 0.0;

varying vec3 v_world;
varying vec3 v_nrm_w;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_nrm_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (dither_on && PROJECTION_MATRIX[3][3] == 0.0
			&& sn_occluded(v_world, cam_pos, arena_rect, dither_margin, dither_density, FRAGCOORD.xy)) {
		discard;
	}
	float g = COLOR.r;
	if (world_gradient) {
		g = clamp((v_world.y - world_gradient_range.x) / (world_gradient_range.y - world_gradient_range.x), 0.0, 1.0);
	}
	vec3 c = mix(color_low.rgb, color_high.rgb, g);
	float patch = sn_fbm3(v_world * patch_scale);
	c = mix(c, color_patch.rgb, smoothstep(0.42, 0.72, patch) * patch_amount);
	// Pinceladas: ruído esticado ao longo do plano da face, valor sobe e desce de leve.
	vec3 sp = v_world * stroke_scale;
	float stroke = sn_noise3(vec3(sp.x * 0.35, sp.y * 1.6, sp.z * 0.35) + 3.1);
	c *= 1.0 + (stroke - 0.5) * 2.0 * stroke_amount;
	if (top_amount > 0.0) {
		float up = pow(clamp(v_nrm_w.y, 0.0, 1.0), top_sharpness);
		float edge = sn_noise3(v_world * 1.7 + 9.0);
		c = mix(c, top_color.rgb, clamp(up * top_amount * (0.75 + 0.5 * edge), 0.0, 1.0));
	}
	c *= mix(1.0, COLOR.g, vertex_ao);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	EMISSION = emission_color.rgb * emission_energy;
}

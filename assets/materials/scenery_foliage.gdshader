shader_type spatial;
render_mode cull_disabled, specular_disabled, alpha_to_coverage;
// Folhagem pintada (spec 012, Fase 2; arte A08): copas de lóbulos feitas de cartões de tufo
// (leaf_clumps_*, atlas 4x4) e coníferas em andares de cartões (conifer_tiers, atlas 4x2).
// Alpha scissor + alpha-to-coverage (MSAA). Normais "esféricas" vêm da malha (do centro da copa ou do
// eixo da conífera). Luz embrulhada (wrap) e luz de borda quente contra o sol no light().
// Cor do vértice: r = altura na copa (gradiente), g = luz (1 = sem escurecer), b = tipo do cartão
// (0 tufo, 0,5 andar de conífera, 1 miolo maciço sem recorte), a = variação da peça.
// UV dos cartões: fract = posição no cartão (0..1, v = 0 em cima), floor(UV.y) = célula do atlas.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform int atlas_cols = 4;
uniform int atlas_rows = 4;
uniform vec2 atlas_size = vec2(1024.0, 1024.0);
// Gradiente por altura (multiplica a textura): base fria e escura -> topo claro e quente.
uniform vec4 shade_low : source_color = vec4(0.55, 0.62, 0.62, 1.0);
uniform vec4 shade_high : source_color = vec4(1.08, 1.06, 0.92, 1.0);
// Miolo maciço (preenche entre os cartões, fica na sombra das folhas).
uniform vec4 core_color : source_color = vec4(0.16, 0.26, 0.12, 1.0);
uniform float alpha_cut = 0.5;
uniform float alpha_edge = 0.3;
// Luz embrulhada: 0 = Lambert; 1 = a luz dá a volta até o lado oposto.
uniform float wrap_light = 0.6;
// Luz de borda quente (quando a câmera olha contra o sol).
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.55, 1.0);
uniform float rim_amount = 0.35;
// Translucidez das folhas: luz que atravessa os tufos do lado oposto ao sol.
uniform vec4 backlight_color : source_color = vec4(0.18, 0.2, 0.06, 1.0);
// Balanço lento (amplitude <= 0,03, período de 3 a 6 s, só por TIME).
uniform float sway_amount = 0.02;
uniform float sway_period = 4.5;
uniform bool dither_on = false;
uniform vec3 cam_pos = vec3(0.0, -1000.0, 0.0);
uniform vec4 arena_rect = vec4(-10.0, -9.0, 10.0, 9.0);
uniform float dither_density = 0.6;
uniform float dither_margin = 0.0;

// Véu quente do lado do sol (sn_sun_haze).
uniform vec3 haze_sun_from = vec3(-0.664, 0.695, -0.275);
uniform vec4 haze_color : source_color = vec4(1.0, 0.82, 0.6, 1.0);
uniform float haze_strength = 0.42;
uniform float haze_distance = 40.0;

// Perspectiva aérea (sn_air): além do anfiteatro, a cor vai para o lavanda do ar.
uniform vec4 air_color : source_color = vec4(0.7, 0.72, 0.84, 1.0);
uniform float air_strength = 0.17;
uniform float air_start = 56.0;
uniform float air_distance = 10.0;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Balanço: só o alto da copa (canal r) e devagar.
	float phase = dot(v_world.xz, vec2(0.13, 0.17));
	float s = sin(TIME * 6.2831853 / sway_period + phase) * sway_amount * COLOR.r;
	VERTEX.x += s;
	VERTEX.z += s * 0.6;
}

void fragment() {
	if (dither_on && PROJECTION_MATRIX[3][3] == 0.0
			&& sn_occluded(v_world, cam_pos, arena_rect, dither_margin, dither_density, FRAGCOORD.xy)) {
		discard;
	}
	float g = COLOR.r;
	vec3 shade = mix(shade_low.rgb, shade_high.rgb, g);
	if (COLOR.b > 0.75) {
		// Miolo maciço: cor escura da sombra própria da copa, com um pouco do gradiente.
		ALBEDO = core_color.rgb * mix(0.8, 1.25, g) * COLOR.g;
		ALPHA = 1.0;
	} else {
		int count = atlas_cols * atlas_rows;
		int cell = int(mod(floor(UV.y), float(count)));
		vec2 inner = clamp(vec2(UV.x, fract(UV.y)), vec2(0.004), vec2(0.996));
		vec2 cell_uv = (vec2(float(cell % atlas_cols), float(cell / atlas_cols)) + inner)
				/ vec2(float(atlas_cols), float(atlas_rows));
		vec4 t = texture(atlas, cell_uv);
		ALBEDO = t.rgb * shade * COLOR.g;
		ALPHA = t.a;
		ALPHA_SCISSOR_THRESHOLD = alpha_cut;
		ALPHA_ANTIALIASING_EDGE = alpha_edge;
		ALPHA_TEXTURE_COORDINATE = cell_uv * atlas_size;
	}
	float air = sn_air(v_world, CAMERA_POSITION_WORLD, air_strength, air_start, air_distance);
	ALBEDO *= 1.0 - air;
	EMISSION += air_color.rgb * air;
	EMISSION += sn_sun_haze(v_world, CAMERA_POSITION_WORLD, haze_sun_from, haze_color.rgb, haze_strength, haze_distance);
	ROUGHNESS = 1.0;
	// Cartões de costas: mantém a normal "esférica" da copa (não inverte).
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrapped = clamp((ndl + wrap_light) / (1.0 + wrap_light), 0.0, 1.0);
	DIFFUSE_LIGHT += wrapped * ATTENUATION * LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += clamp(-ndl, 0.0, 1.0) * backlight_color.rgb * ATTENUATION * LIGHT_COLOR / PI;
	// Borda quente: silhueta da copa quando a vista vai contra a luz.
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float against = clamp(dot(-VIEW, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	DIFFUSE_LIGHT += rim * against * rim_amount * rim_color.rgb * ATTENUATION * LIGHT_COLOR / PI;
}

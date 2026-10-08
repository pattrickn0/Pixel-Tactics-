shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
// Folhagem PROVISÓRIA (spec 012, Fase 1): copa de lóbulos feitos de cartões e coníferas em andares de
// cartões. A silhueta de cada cartão vem de uma máscara no shader (ruído com seed fixa), até a A08
// trazer o atlas de tufos. Normais "esféricas" vêm da malha. Cor do vértice: r = altura na copa
// (gradiente), g = luz (1 = sem escurecer), b = tipo do cartão (0 tufo redondo, 1 andar de conífera,
// 2 maciço sem recorte), a = variação da peça.
// UV dos cartões: fract = posição no cartão (0..1), floor(UV.y) = número do cartão (semente).

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 color_low : source_color = vec4(0.20, 0.32, 0.16, 1.0);
uniform vec4 color_mid : source_color = vec4(0.37, 0.54, 0.19, 1.0);
uniform vec4 color_high : source_color = vec4(0.78, 0.85, 0.44, 1.0);
// Pintas de sombra entre os tufos (dá volume sem textura).
uniform float dapple_amount = 0.22;
uniform float alpha_cut = 0.5;
uniform float wrap_light = 1.0;
// Balanço lento (amplitude <= 0,03, período de 3 a 6 s, só por TIME).
uniform float sway_amount = 0.02;
uniform float sway_period = 4.5;
uniform bool dither_on = false;
uniform vec3 cam_pos = vec3(0.0, -1000.0, 0.0);
uniform vec4 arena_rect = vec4(-10.0, -9.0, 10.0, 9.0);
uniform float dither_density = 0.6;
uniform float dither_margin = 0.0;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Balanço: só o alto da copa (canal r) e devagar.
	float phase = dot(v_world.xz, vec2(0.13, 0.17));
	float s = sin(TIME * 6.2831853 / sway_period + phase) * sway_amount * COLOR.r;
	VERTEX.x += s;
	VERTEX.z += s * 0.6;
}

float clump_mask(vec2 uv, float seed) {
	vec2 d = uv - 0.5;
	float r = length(d) * 2.0;
	float a = atan(d.y, d.x);
	// Borda em tufos: lóbulos irregulares, com fiapos de folha.
	float lobes = 0.80 + 0.09 * sin(a * 5.0 + seed * 6.3) + 0.06 * sin(a * 9.0 + seed * 2.1);
	float leaf = sn_noise2(vec2(a * 4.0, r * 5.0) + seed * 13.0);
	return lobes + (leaf - 0.5) * 0.22 - r;
}

float tier_mask(vec2 uv, float seed) {
	// v = 0 em cima, 1 na ponta de baixo; pontas serrilhadas na borda de baixo.
	float teeth = abs(fract(uv.x * 4.0 + seed) - 0.5) * 2.0;
	float edge = 0.86 - teeth * 0.22 + (sn_noise2(vec2(uv.x * 11.0, seed * 7.0)) - 0.5) * 0.08;
	float sides = min(uv.x, 1.0 - uv.x) * 2.0;
	return min(edge - uv.y, sides + 0.25 - uv.y * 0.15);
}

void fragment() {
	if (dither_on && PROJECTION_MATRIX[3][3] == 0.0
			&& sn_occluded(v_world, cam_pos, arena_rect, dither_margin, dither_density, FRAGCOORD.xy)) {
		discard;
	}
	vec2 cell = fract(UV);
	float seed = floor(UV.y) * 0.618 + COLOR.a * 3.7;
	float kind = COLOR.b;
	float m = 1.0;
	if (kind < 0.25) {
		m = clump_mask(cell, seed);
	} else if (kind < 0.75) {
		m = tier_mask(cell, seed);
	}
	ALPHA = m > 0.0 ? 1.0 : 0.0;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	float g = COLOR.r;
	vec3 c = g < 0.5 ? mix(color_low.rgb, color_mid.rgb, g * 2.0) : mix(color_mid.rgb, color_high.rgb, (g - 0.5) * 2.0);
	// Pintas: folhas mais escuras para dentro do tufo, mais claras na borda de cima.
	float dapple = sn_noise2(cell * 5.0 + seed * 9.0);
	float rim = kind < 0.25 ? smoothstep(0.0, 0.25, 0.25 - clamp(m, 0.0, 0.25)) : 0.0;
	c *= 1.0 - dapple_amount * smoothstep(0.45, 0.8, dapple) * (1.0 - rim);
	c = mix(c, color_high.rgb, rim * 0.25 * g);
	if (kind > 0.25 && kind < 0.75) {
		// Andar de conífera: miolo mais escuro, pontas mais claras.
		c *= mix(0.78, 1.08, cell.y);
	}
	c *= COLOR.g;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	// Cartões de costas: mantém a normal "esférica" da copa (não inverte).
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	BACKLIGHT = vec3(0.12, 0.14, 0.06) * wrap_light;
}

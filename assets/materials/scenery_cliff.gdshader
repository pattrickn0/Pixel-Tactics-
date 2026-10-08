shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// Penhasco e fundo da ilha pintados (spec 012, Fase 3; arte A08 leva 2: island/cliff e island/under, 8 x 8
// unidades, seamless nos 2 eixos). Projeção triplanar no mundo (as faces em blocos e o fundo cônico não têm UV
// bom) com normal map suave. A face escurece e esfria para baixo e some no ar lavanda (a névoa de altura da
// cena faz o resto). As faces viradas para cima (degraus do penhasco, topo das rochas) ganham grama/musgo.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
// Tamanho da textura em unidades do mundo (512 px a 64 px por unidade = 8).
uniform float tex_units = 8.0;
uniform float normal_scale = 0.5;
// Nitidez da mistura entre as 3 projeções.
uniform float blend_sharpness = 4.0;
uniform vec4 tint : source_color = vec4(1.0);
// Gradiente pela altura no mundo: abaixo de gradient_range.x fica deep_color (frio e escuro).
uniform vec2 gradient_range = vec2(-14.0, 0.0);
uniform vec4 deep_color : source_color = vec4(0.243, 0.212, 0.251, 1.0);
uniform float deep_amount = 0.7;
// Topo: grama/musgo nas faces viradas para cima, em manchas.
uniform vec4 top_color : source_color = vec4(0.34, 0.4, 0.12, 1.0);
uniform float top_amount = 0.0;
// Altura local da peça (rochas e ilhotas): usa o y do objeto em vez do mundo.
uniform bool local_gradient = false;
uniform float vertex_ao = 0.0;
// Dither de oclusão (OcclusionDither entrega cam_pos e arena_rect).
uniform bool dither_on = false;
uniform vec3 cam_pos = vec3(0.0, -1000.0, 0.0);
uniform vec4 arena_rect = vec4(-10.0, -9.0, 10.0, 9.0);
uniform float dither_density = 0.6;
uniform float dither_margin = 0.0;
// Perspectiva aérea (sn_air): além do anfiteatro, a cor vai para o lavanda do ar.
uniform vec4 air_color : source_color = vec4(0.7, 0.72, 0.84, 1.0);
uniform float air_strength = 0.03;
uniform float air_start = 56.0;
uniform float air_distance = 10.0;

varying vec3 v_world;
varying vec3 v_local;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_local = VERTEX;
}

void fragment() {
	if (dither_on && PROJECTION_MATRIX[3][3] == 0.0
			&& sn_occluded(v_world, cam_pos, arena_rect, dither_margin, dither_density, FRAGCOORD.xy)) {
		discard;
	}
	// Normal geométrica no mundo (faces planas dos blocos).
	vec3 gn = normalize(cross(dFdx(v_world), dFdy(v_world)));
	vec3 vn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (dot(gn, vn) < 0.0) {
		gn = -gn;
	}
	vec3 w = pow(abs(gn), vec3(blend_sharpness));
	w /= max(w.x + w.y + w.z, 0.0001);
	vec3 p = v_world / tex_units;
	float sx = gn.x >= 0.0 ? 1.0 : -1.0;
	float sy = gn.y >= 0.0 ? 1.0 : -1.0;
	float sz = gn.z >= 0.0 ? 1.0 : -1.0;
	// v = -y nas faces verticais (o alto da textura fica em cima).
	vec2 uv_x = vec2(-sx * p.z, -p.y);
	vec2 uv_y = vec2(p.x, p.z);
	vec2 uv_z = vec2(sz * p.x, -p.y);
	vec3 col = texture(albedo_tex, uv_x).rgb * w.x + texture(albedo_tex, uv_y).rgb * w.y + texture(albedo_tex, uv_z).rgb * w.z;
	col *= tint.rgb;
	float h = local_gradient ? v_local.y : v_world.y;
	float g = clamp((h - gradient_range.x) / (gradient_range.y - gradient_range.x), 0.0, 1.0);
	col = mix(deep_color.rgb, col, mix(1.0 - deep_amount, 1.0, g));
	if (top_amount > 0.0) {
		float up = smoothstep(0.55, 0.9, gn.y);
		float patches = smoothstep(0.3, 0.65, sn_fbm3(v_world * 0.9 + 2.0));
		col = mix(col, top_color.rgb * (0.8 + 0.4 * sn_noise3(v_world * 5.0)), up * mix(0.6, 1.0, patches) * top_amount);
	}
	col *= mix(1.0, COLOR.g, vertex_ao);
	float air = sn_air(v_world, CAMERA_POSITION_WORLD, air_strength, air_start, air_distance);
	ALBEDO = col * (1.0 - air);
	EMISSION += air_color.rgb * air;
	ROUGHNESS = 1.0;
	// Normal map triplanar: cada projeção com o próprio triedro (tangente, "para cima" da imagem, normal do eixo).
	vec3 nx = texture(normal_tex, uv_x).xyz * 2.0 - 1.0;
	vec3 ny = texture(normal_tex, uv_y).xyz * 2.0 - 1.0;
	vec3 nz = texture(normal_tex, uv_z).xyz * 2.0 - 1.0;
	nx.xy *= normal_scale;
	ny.xy *= normal_scale;
	nz.xy *= normal_scale;
	vec3 wx = vec3(0.0, 0.0, -sx) * nx.x + vec3(0.0, 1.0, 0.0) * nx.y + vec3(sx, 0.0, 0.0) * nx.z;
	vec3 wy = vec3(1.0, 0.0, 0.0) * ny.x + vec3(0.0, 0.0, -1.0) * ny.y + vec3(0.0, sy, 0.0) * ny.z;
	vec3 wz = vec3(sz, 0.0, 0.0) * nz.x + vec3(0.0, 1.0, 0.0) * nz.y + vec3(0.0, 0.0, sz) * nz.z;
	vec3 pn = normalize(wx * w.x + wy * w.y + wz * w.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(pn, 0.0)).xyz);
}

shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// Pedra e madeira pintadas (spec 012, Fase 2; arte A08): muro, crista, degraus, lajes e casca.
// Filtro linear com mipmaps e anisotrópico; 64 px por unidade (uv_scale = 1 / tamanho da textura em
// unidades, calculado de WorldScale.SCENERY_TEXELS_PER_UNIT em KitMaterialDefs).
// uv_mode 0 = UV da malha (uv * uv_scale + uv_offset; casca: v = 1 no chão).
// uv_mode 1 = projeção no mundo pelo eixo dominante da normal GEOMÉTRICA da face; faces verticais com
//             v = v_top - y (v = 0 no topo da face: o musgo escorre de cima).
// uv_mode 2 = faixa: u = posição no mundo ao longo do eixo X (ou Z) local da peça, v = UV.y da malha
//             (distância da borda de fora, em unidades).
// Extras: musgo pela normal (faces viradas para cima), tom por laje (canal r da cor do vértice, se
// shade_from_color) e AO pela cor do vértice (canal g).

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_normal = false;
uniform float normal_scale = 0.5;
uniform vec4 tint : source_color = vec4(1.0);
uniform int uv_mode = 0;
uniform bool world_space = true;
uniform int strip_axis = 0;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform float v_top = 0.0;
uniform float alpha_cut = -1.0;
// Musgo pela normal: cobre o alto das faces viradas para cima, em manchas (ruído de mundo, seed fixa).
uniform vec4 moss_color : source_color = vec4(0.53, 0.635, 0.227, 1.0);
uniform float moss_amount = 0.0;
// Tom por laje: canal r da cor do vértice (0 a 1) varia o valor em +-shade_amount.
uniform bool shade_from_color = false;
uniform float shade_amount = 0.08;
uniform float vertex_ao = 1.0;
// Dither de oclusão: some em pontos o que fica entre a câmera e a arena.
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

varying vec3 v_pos;
varying vec3 v_nrm;
varying vec3 v_world;
varying vec3 v_nrm_w;
varying float v_strip_u;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_nrm_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (world_space) {
		v_pos = v_world;
		v_nrm = v_nrm_w;
	} else {
		v_pos = VERTEX;
		v_nrm = NORMAL;
	}
	vec3 axis_local = strip_axis == 0 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec2 axis_world = (MODEL_MATRIX * vec4(axis_local, 0.0)).xz;
	// Malha juntada (MeshMerger): o eixo da faixa da peça original vem no UV2.
	if (dot(UV2, UV2) > 0.25) {
		axis_world = UV2;
	}
	v_strip_u = dot(v_world.xz, axis_world);
}

void fragment() {
	vec3 n = normalize(v_nrm);
	vec3 gn = normalize(cross(dFdx(v_pos), dFdy(v_pos)));
	if (dot(gn, n) < 0.0) {
		gn = -gn;
	}
	vec3 dpw_x = dFdx(v_world);
	vec3 dpw_y = dFdy(v_world);
	if (dither_on && PROJECTION_MATRIX[3][3] == 0.0
			&& sn_occluded(v_world, cam_pos, arena_rect, dither_margin, dither_density, FRAGCOORD.xy)) {
		discard;
	}

	vec2 uv = UV;
	vec3 tan_p = vec3(1.0, 0.0, 0.0);
	vec3 bit_p = vec3(0.0, 1.0, 0.0);
	if (uv_mode == 1) {
		vec3 a = abs(gn);
		if (a.y >= a.x && a.y >= a.z) {
			uv = v_pos.xz;
			bit_p = vec3(0.0, 0.0, -1.0);
		} else if (a.x >= a.z) {
			float s = gn.x >= 0.0 ? 1.0 : -1.0;
			uv = vec2(-s * v_pos.z, v_top - v_pos.y);
			tan_p = vec3(0.0, 0.0, -s);
		} else {
			float s = gn.z >= 0.0 ? 1.0 : -1.0;
			uv = vec2(s * v_pos.x, v_top - v_pos.y);
			tan_p = vec3(s, 0.0, 0.0);
		}
		uv = uv * uv_scale + uv_offset;
	} else if (uv_mode == 2) {
		uv = vec2(v_strip_u, UV.y) * uv_scale + uv_offset;
	} else {
		uv = uv * uv_scale + uv_offset;
	}
	vec4 c = texture(albedo_tex, uv) * tint;
	if (alpha_cut >= 0.0 && c.a < alpha_cut) {
		discard;
	}
	vec3 col = c.rgb;
	if (shade_from_color) {
		col *= 1.0 + (COLOR.r - 0.5) * 2.0 * shade_amount;
	}
	if (moss_amount > 0.0) {
		float up = smoothstep(0.55, 0.95, normalize(v_nrm_w).y);
		float patches = smoothstep(0.35, 0.7, sn_fbm3(v_world * 1.3 + 4.0));
		col = mix(col, moss_color.rgb * (0.8 + 0.4 * sn_noise3(v_world * 6.0)), up * patches * moss_amount);
	}
	col *= mix(1.0, COLOR.g, vertex_ao);
	EMISSION += sn_sun_haze(v_world, CAMERA_POSITION_WORLD, haze_sun_from, haze_color.rgb, haze_strength, haze_distance);
	float air = sn_air(v_world, CAMERA_POSITION_WORLD, air_strength, air_start, air_distance);
	ALBEDO = col * (1.0 - air);
	EMISSION += air_color.rgb * air;
	ROUGHNESS = 1.0;
	if (use_normal) {
		vec3 nm = texture(normal_tex, uv).xyz * 2.0 - 1.0;
		nm.xy *= normal_scale;
		vec3 pn;
		if (uv_mode == 1) {
			vec3 t_w = tan_p;
			vec3 b_w = bit_p;
			vec3 g_w = gn;
			if (!world_space) {
				t_w = (MODEL_MATRIX * vec4(tan_p, 0.0)).xyz;
				b_w = (MODEL_MATRIX * vec4(bit_p, 0.0)).xyz;
				g_w = (MODEL_MATRIX * vec4(gn, 0.0)).xyz;
			}
			pn = normalize(normalize(t_w) * nm.x + normalize(b_w) * nm.y + normalize(g_w) * nm.z);
		} else {
			// Faixa e UV da malha: triedro por derivadas (cotangent frame) sobre a normal geométrica do mundo.
			vec3 g_w = normalize(cross(dpw_x, dpw_y));
			if (dot(g_w, v_nrm_w) < 0.0) {
				g_w = -g_w;
			}
			if (uv_mode == 0) {
				// Superfície curva (casca): a normal suave da malha no lugar da geométrica.
				g_w = normalize(v_nrm_w);
			}
			vec2 d1 = dFdx(uv);
			vec2 d2 = dFdy(uv);
			vec3 p2 = cross(dpw_y, g_w);
			vec3 p1 = cross(g_w, dpw_x);
			vec3 t_w = p2 * d1.x + p1 * d2.x;
			vec3 b_w = -(p2 * d1.y + p1 * d2.y);
			float inv = inversesqrt(max(max(dot(t_w, t_w), dot(b_w, b_w)), 1e-12));
			pn = normalize(t_w * inv * nm.x + b_w * inv * nm.y + g_w * nm.z);
		}
		NORMAL = normalize((VIEW_MATRIX * vec4(pn, 0.0)).xyz);
	}
}

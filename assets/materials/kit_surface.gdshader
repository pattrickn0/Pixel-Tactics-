shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// Superfície única do kit do mapa (spec 011). 32 texels por unidade em tudo, filtro Nearest.
// uv_mode 0 = UV da malha (decalques, cartões, caixote...).
// uv_mode 1 = projeção pelo eixo dominante da normal GEOMÉTRICA da face (derivadas da posição),
//             não da normal de sombreamento (a copa usa normais "esféricas" só para a luz); no
//             espaço do mundo a textura corre contínua de uma peça para a outra (muros, chão).
//             v = v_top - y nas faces verticais.
// uv_mode 2 = faixa: u vem da posição no mundo ao longo do eixo X (ou Z) local da peça,
//             v vem da malha (capeamento, topo da crista, musgo pendente).
// Troca de textura (fase 3): só o parâmetro albedo_tex / normal_tex do .tres.

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_nearest_mipmap, repeat_enable;
uniform bool use_normal = false;
uniform float normal_scale = 0.5;
uniform vec4 tint : source_color = vec4(1.0);
uniform int uv_mode = 0;
uniform bool world_space = true;
uniform int strip_axis = 0;
uniform vec2 uv_scale = vec2(1.0);
uniform float v_top = 0.0;
uniform float alpha_cut = -1.0;
uniform bool clamp_uv = false;
// Dither de oclusão: some em pontos o que fica entre a câmera e a arena.
uniform bool dither_on = false;
uniform vec3 cam_pos = vec3(0.0, -1000.0, 0.0);
uniform vec4 arena_rect = vec4(-10.0, -9.0, 10.0, 9.0);
uniform float dither_density = 0.6;
// Folga em volta da arena (árvores protegem também reservas e terraço; muros só a arena).
uniform float dither_margin = 0.0;

varying vec3 v_pos;
varying vec3 v_nrm;
varying vec3 v_world;
varying vec3 v_nrm_w;
varying float v_strip_u;

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(floor(p), 4.0));
	int idx = i.x + i.y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[idx] + 0.5) / 16.0;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_nrm_w = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (world_space) {
		v_pos = v_world;
		v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	} else {
		v_pos = VERTEX;
		v_nrm = NORMAL;
	}
	vec3 axis_local = strip_axis == 0 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec2 axis_world = (MODEL_MATRIX * vec4(axis_local, 0.0)).xz;
	// Malha juntada (MeshMerger, spec 012): o eixo da faixa da peça original vem no UV2.
	if (dot(UV2, UV2) > 0.25) {
		axis_world = UV2;
	}
	v_strip_u = dot(v_world.xz, axis_world);
}

void fragment() {
	// Derivadas antes de qualquer discard: normal geométrica da face (orientada para o lado da
	// normal de sombreamento) e a posição no mundo para o triedro do normal map em faixa.
	vec3 n = normalize(v_nrm);
	vec3 gn = normalize(cross(dFdx(v_pos), dFdy(v_pos)));
	if (dot(gn, n) < 0.0) {
		gn = -gn;
	}
	vec3 dpw_x = dFdx(v_world);
	vec3 dpw_y = dFdy(v_world);

	// Dither só na câmera em perspectiva (a sombra do sol é ortográfica e fica inteira).
	if (dither_on && PROJECTION_MATRIX[3][3] == 0.0 && cam_pos.y > v_world.y + 0.05) {
		float t = cam_pos.y / (cam_pos.y - v_world.y);
		vec3 q = cam_pos + (v_world - cam_pos) * t;
		vec4 r = arena_rect + vec4(-dither_margin, -dither_margin, dither_margin, dither_margin);
		float inside = min(min(q.x - r.x, r.z - q.x), min(q.z - r.y, r.w - q.z));
		if (inside > 0.0) {
			float amount = clamp(inside * 0.5 + 0.35, 0.0, 1.0) * dither_density;
			if (bayer4(FRAGCOORD.xy) < amount) {
				discard;
			}
		}
	}

	vec2 uv = UV;
	// Triedro da projeção (no espaço de v_pos): tangente = +u, bitangente = para cima na imagem.
	vec3 tan_p = vec3(1.0, 0.0, 0.0);
	vec3 bit_p = vec3(0.0, 1.0, 0.0);
	if (uv_mode == 1) {
		vec3 a = abs(gn);
		if (a.y >= a.x && a.y >= a.z) {
			uv = v_pos.xz;
			tan_p = vec3(1.0, 0.0, 0.0);
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
		uv *= uv_scale;
	} else if (uv_mode == 2) {
		uv = vec2(v_strip_u, UV.y) * uv_scale;
	} else {
		uv *= uv_scale;
	}
	if (clamp_uv) {
		uv = clamp(uv, vec2(0.0), vec2(1.0));
	}
	vec4 c = texture(albedo_tex, uv) * tint;
	if (alpha_cut >= 0.0 && c.a < alpha_cut) {
		discard;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	if (use_normal) {
		if (uv_mode == 0) {
			NORMAL_MAP = texture(normal_tex, uv).xyz;
			NORMAL_MAP_DEPTH = normal_scale;
		} else {
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
				// Faixa: triedro por derivadas (cotangent frame) em cima da normal geométrica do mundo.
				vec3 g_w = normalize(cross(dpw_x, dpw_y));
				if (dot(g_w, v_nrm_w) < 0.0) {
					g_w = -g_w;
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
}

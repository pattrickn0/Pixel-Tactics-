shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// Superfície única do kit do mapa (spec 011). 32 texels por unidade em tudo, filtro Nearest.
// uv_mode 0 = UV da malha (decalques, cartões, caixote...).
// uv_mode 1 = projeção pelo eixo dominante da normal; no espaço do mundo a textura corre
//             contínua de uma peça para a outra (muros, chão). v = v_top - y nas faces verticais.
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
varying float v_strip_u;

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(floor(p), 4.0));
	int idx = i.x + i.y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[idx] + 0.5) / 16.0;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (world_space) {
		v_pos = v_world;
		v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	} else {
		v_pos = VERTEX;
		v_nrm = NORMAL;
	}
	vec3 axis_local = strip_axis == 0 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec2 axis_world = (MODEL_MATRIX * vec4(axis_local, 0.0)).xz;
	v_strip_u = dot(v_world.xz, axis_world);
}

void fragment() {
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
	vec3 tan_w = vec3(1.0, 0.0, 0.0);
	vec3 bit_w = vec3(0.0, 1.0, 0.0);
	vec3 n = normalize(v_nrm);
	if (uv_mode == 1) {
		vec3 a = abs(n);
		if (a.y >= a.x && a.y >= a.z) {
			uv = v_pos.xz;
			tan_w = vec3(1.0, 0.0, 0.0);
			bit_w = vec3(0.0, 0.0, -1.0);
		} else if (a.x >= a.z) {
			float s = n.x >= 0.0 ? 1.0 : -1.0;
			uv = vec2(-s * v_pos.z, v_top - v_pos.y);
			tan_w = vec3(0.0, 0.0, -s);
		} else {
			float s = n.z >= 0.0 ? 1.0 : -1.0;
			uv = vec2(s * v_pos.x, v_top - v_pos.y);
			tan_w = vec3(s, 0.0, 0.0);
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
		} else if (uv_mode == 1 && world_space) {
			vec3 nm = texture(normal_tex, uv).xyz * 2.0 - 1.0;
			nm.xy *= normal_scale;
			vec3 pn = normalize(tan_w * nm.x + bit_w * nm.y + n * nm.z);
			NORMAL = normalize((VIEW_MATRIX * vec4(pn, 0.0)).xyz);
		}
	}
}

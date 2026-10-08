// Ruído de valor com semente fixa (spec 012, D1: ruído com seed fixa é permitido nos shaders).
// Só aritmética sobre a posição: o mesmo ponto dá sempre o mesmo valor.

float sn_hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float sn_hash2(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float sn_noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = sn_hash2(i);
	float b = sn_hash2(i + vec2(1.0, 0.0));
	float c = sn_hash2(i + vec2(0.0, 1.0));
	float d = sn_hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float sn_noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = sn_hash3(i);
	float n100 = sn_hash3(i + vec3(1.0, 0.0, 0.0));
	float n010 = sn_hash3(i + vec3(0.0, 1.0, 0.0));
	float n110 = sn_hash3(i + vec3(1.0, 1.0, 0.0));
	float n001 = sn_hash3(i + vec3(0.0, 0.0, 1.0));
	float n101 = sn_hash3(i + vec3(1.0, 0.0, 1.0));
	float n011 = sn_hash3(i + vec3(0.0, 1.0, 1.0));
	float n111 = sn_hash3(i + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, u.x);
	float x10 = mix(n010, n110, u.x);
	float x01 = mix(n001, n101, u.x);
	float x11 = mix(n011, n111, u.x);
	return mix(mix(x00, x10, u.y), mix(x01, x11, u.y), u.z);
}

// Duas oitavas: manchas grandes com borda um pouco quebrada.
float sn_fbm3(vec3 p) {
	return sn_noise3(p) * 0.65 + sn_noise3(p * 2.03 + 17.1) * 0.35;
}

float sn_fbm2(vec2 p) {
	return sn_noise2(p) * 0.6 + sn_noise2(p * 2.07 + 11.3) * 0.28 + sn_noise2(p * 4.11 + 5.7) * 0.12;
}

float sn_bayer4(vec2 p) {
	ivec2 i = ivec2(mod(floor(p), 4.0));
	int idx = i.x + i.y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[idx] + 0.5) / 16.0;
}

// Dither de oclusão (mesma regra do kit_surface): some em pontos o que fica entre a câmera e a arena.
bool sn_occluded(vec3 world, vec3 cam, vec4 arena, float margin, float density, vec2 frag) {
	if (cam.y <= world.y + 0.05) {
		return false;
	}
	float t = cam.y / (cam.y - world.y);
	vec3 q = cam + (world - cam) * t;
	vec4 r = arena + vec4(-margin, -margin, margin, margin);
	float inside = min(min(q.x - r.x, r.z - q.x), min(q.z - r.y, r.w - q.z));
	if (inside <= 0.0) {
		return false;
	}
	float amount = clamp(inside * 0.5 + 0.35, 0.0, 1.0) * density;
	return sn_bayer4(frag) < amount;
}

// Brilho do sol espalhado no ar (spec 012, Fase 2): do lado da vista que fica contra o sol, o cenário ganha
// um véu quente que cresce com a distância (como a referência, quente no alto à esquerda). Vai na emissão
// (não depende da luz). sun_from = de onde vem o sol (oposto à luz do Sun da cena principal).
vec3 sn_sun_haze(vec3 world, vec3 cam, vec3 sun_from, vec3 color, float strength, float dist_scale) {
	vec3 d = world - cam;
	float dist = length(d);
	vec2 dh = normalize(d.xz + vec2(0.0001));
	vec2 sh = normalize(sun_from.xz + vec2(0.0001));
	float side = smoothstep(0.5, 1.0, dot(dh, sh));
	// Começa a 30 unidades da câmera: de perto o ar é limpo.
	return color * strength * side * side * (1.0 - exp(-max(dist - 30.0, 0.0) / dist_scale));
}

// Perspectiva aérea (spec 012, Fase 2): além do anfiteatro, a cor vai aos poucos para o lavanda do ar (a névoa de
// profundidade da cena só começa depois da borda). Devolve a fração (0 a 1) de troca da cor pelo ar.
float sn_air(vec3 world, vec3 cam, float strength, float start, float dist_scale) {
	float dist = length(world - cam);
	return strength * (1.0 - exp(-max(dist - start, 0.0) / dist_scale));
}

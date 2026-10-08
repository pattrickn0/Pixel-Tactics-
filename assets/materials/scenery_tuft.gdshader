shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;
// Tufos de grama e flores PROVISÓRIOS (spec 012, Fase 1), em MultiMesh: cartões cruzados com as
// folhas desenhadas por máscara no shader (seed fixa). Normal para cima (assenta no chão).
// UV: fract = posição no cartão, floor(UV.y) = semente. Nas flores, a cor da instância pinta as pétalas.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 base_color : source_color = vec4(0.247, 0.373, 0.133, 1.0);
uniform vec4 tip_color : source_color = vec4(0.659, 0.769, 0.278, 1.0);
uniform bool flower_mode = false;

varying float v_seed;

void vertex() {
	// Cada instância do MultiMesh desenha folhas diferentes.
	v_seed = float(INSTANCE_ID) * 0.137;
}

void fragment() {
	vec2 uv = fract(UV);
	float seed = floor(UV.y) * 0.37 + v_seed;
	// Folhas: 5 lâminas triangulares de alturas diferentes.
	float h = 0.0;
	for (int k = 0; k < 5; k++) {
		float fk = float(k);
		float cx = 0.12 + fk * 0.19 + (sn_hash2(vec2(fk, seed)) - 0.5) * 0.08;
		float bh = 0.55 + sn_hash2(vec2(seed, fk + 3.0)) * 0.45;
		float w = 0.11 + sn_hash2(vec2(fk + 7.0, seed)) * 0.05;
		h = max(h, bh * (1.0 - abs(uv.x - cx) / w));
	}
	float up = 1.0 - uv.y;
	float blade = h - up;
	vec3 c = mix(base_color.rgb, tip_color.rgb, smoothstep(0.0, 0.9, up));
	float a = blade;
	if (flower_mode) {
		// Flores: 3 cabecinhas redondas no alto, cabinho fino.
		float petals = -1.0;
		for (int k = 0; k < 3; k++) {
			float fk = float(k);
			vec2 cc = vec2(0.22 + fk * 0.28, 0.18 + sn_hash2(vec2(fk, seed + 1.0)) * 0.2);
			petals = max(petals, 0.11 - length(uv - cc));
		}
		float stem = 0.035 - abs(fract(uv.x * 3.57 + 0.2) - 0.5) * 0.28;
		stem = up < 0.75 ? stem : -1.0;
		a = max(max(petals, stem), blade * 0.6 - 0.15);
		c = petals > 0.0 ? COLOR.rgb : c;
	}
	ALPHA = a > 0.0 ? 1.0 : 0.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}

shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled, alpha_to_coverage;
// Tufos de grama e flores pintados (spec 012, Fase 2; arte A08), em MultiMesh: 3 cartões cruzados com
// uma célula do atlas (grass_tufts 4x2, base embaixo; flowers 4x4 com 12 grupos). A célula sai do número
// da instância e do cartão (fixo, sem sorteio). Normal para cima (assenta no chão, luz igual à do chão).
// UV: x e fract(y) = posição no cartão (v = 0 em cima), floor(UV.y) = número do cartão.

uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform int atlas_cols = 4;
uniform int atlas_rows = 2;
uniform vec2 atlas_size = vec2(512.0, 256.0);
// Células usadas: de first_cell a first_cell + cell_count - 1.
uniform int first_cell = 0;
uniform int cell_count = 4;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_cut = 0.5;
uniform float alpha_edge = 0.3;

varying flat int v_instance;

void vertex() {
	v_instance = INSTANCE_ID;
}

void fragment() {
	int card = int(floor(UV.y));
	int cell = first_cell + (v_instance * 3 + card * 5) % max(cell_count, 1);
	vec2 inner = clamp(vec2(UV.x, fract(UV.y)), vec2(0.004), vec2(0.996));
	vec2 cell_uv = (vec2(float(cell % atlas_cols), float(cell / atlas_cols)) + inner)
			/ vec2(float(atlas_cols), float(atlas_rows));
	vec4 t = texture(atlas, cell_uv);
	ALBEDO = t.rgb * tint.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ALPHA_ANTIALIASING_EDGE = alpha_edge;
	ALPHA_TEXTURE_COORDINATE = cell_uv * atlas_size;
	ROUGHNESS = 1.0;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}

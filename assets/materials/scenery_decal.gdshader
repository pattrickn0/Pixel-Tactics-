shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled, alpha_to_coverage;
// Pedras e lajes soltas da arena (spec 012, Fase 2; arte A08 arena_slabs): quads planos com UV direto no
// atlas, alpha scissor + alpha-to-coverage (borda suave com MSAA, sem ordenar transparência).

uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 atlas_size = vec2(1024.0, 512.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_cut = 0.5;
uniform float alpha_edge = 0.4;

void fragment() {
	vec4 t = texture(atlas, UV);
	ALBEDO = t.rgb * tint.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ALPHA_ANTIALIASING_EDGE = alpha_edge;
	ALPHA_TEXTURE_COORDINATE = UV * atlas_size;
	ROUGHNESS = 1.0;
}

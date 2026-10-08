shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled, blend_mix, depth_draw_never;
// Decalques da arena (spec 012, Fase 2; arte A08): a mancha de terra (arena_dirt, 16 x 12 unidades) e o
// centro do círculo (arena_ring, 6 x 6), compostos no mesmo plano, com alfa suave. Plano: a arena
// continua sem obstáculo. UV = posição no mundo (x, z). Imagem: x = leste, y = sul.

uniform sampler2D dirt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D ring_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 dirt_center = vec2(0.3, -1.0);
uniform vec2 dirt_size = vec2(16.0, 12.0);
uniform vec2 ring_center = vec2(0.4, -0.9);
uniform vec2 ring_size = vec2(6.0, 6.0);
uniform vec4 tint : source_color = vec4(1.0);

vec4 decal(sampler2D tex, vec2 p, vec2 center, vec2 size) {
	vec2 uv = (p - center) / size + 0.5;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	return texture(tex, uv);
}

void fragment() {
	vec2 p = UV;
	vec4 d = decal(dirt_tex, p, dirt_center, dirt_size);
	vec4 r = decal(ring_tex, p, ring_center, ring_size);
	// "Por cima": o círculo sobre a terra.
	float a = r.a + d.a * (1.0 - r.a);
	vec3 c = (r.rgb * r.a + d.rgb * d.a * (1.0 - r.a)) / max(a, 0.0001);
	ALBEDO = c * tint.rgb;
	ALPHA = a;
	ROUGHNESS = 1.0;
}

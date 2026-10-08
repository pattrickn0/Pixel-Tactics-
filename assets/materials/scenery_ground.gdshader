shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// Chão de grama pintado (spec 012, Fase 2; arte A08): grass_a e grass_b misturadas pela blend_mask em
// espaço de mundo. Máscara: R = mistura a <-> b, G = mais seco, B = variação de valor. A grama b é
// amostrada girada e deslocada (quebra a repetição do tile de 8 unidades). Canal g da cor do vértice =
// AO (pé do muro e borda da arena). Escala: tile_units e mask_units vêm de WorldScale (64 px por unidade).

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform sampler2D grass_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D blend_mask : filter_linear_mipmap, repeat_enable;
// Tamanho em unidades do mundo de cada textura.
uniform float tile_units = 8.0;
uniform float mask_units = 32.0;
// Desloca a amostragem (dentro e fora do anel ficam com manchas diferentes).
uniform vec2 offset = vec2(0.0, 0.0);
// Cor final: multiplicador geral, tom seco (G da máscara) e força da variação de valor (B).
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 dry_tint : source_color = vec4(1.08, 1.0, 0.72, 1.0);
uniform float dry_amount = 0.35;
uniform float value_amount = 0.12;
// Manchas grandes de luz e sombra (ruído com seed fixa da própria máscara, em escala maior).
uniform float patch_units = 61.0;
uniform float patch_amount = 0.12;
// Mancha escura puxa para verde frio; clara, para amarelo quente (como a grama ao sol da referência).
uniform vec4 patch_dark : source_color = vec4(0.8, 0.9, 0.86, 1.0);
uniform vec4 patch_light : source_color = vec4(1.1, 1.06, 0.86, 1.0);
uniform float vertex_ao = 1.0;
// Suaviza o miúdo da textura (mistura com um mip mais alto): de longe a grama lê como manchas e
// pinceladas, não como carpete.
uniform float detail_soften = 0.35;
uniform float soften_bias = 2.5;


// Perspectiva aérea (sn_air): além do anfiteatro, a cor vai para o lavanda do ar.
uniform vec4 air_color : source_color = vec4(0.7, 0.72, 0.84, 1.0);
uniform float air_strength = 0.03;
uniform float air_start = 56.0;
uniform float air_distance = 10.0;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_world.xz + offset;
	vec3 m = texture(blend_mask, p / mask_units).rgb;
	vec2 uv = p / tile_units;
	// b girada 90° e deslocada: as duas nunca repetem juntas.
	vec2 uv_b = vec2(-uv.y, uv.x) + vec2(0.37, 0.61);
	vec3 a = mix(texture(grass_a, uv).rgb, texture(grass_a, uv, soften_bias).rgb, detail_soften);
	vec3 b = mix(texture(grass_b, uv_b).rgb, texture(grass_b, uv_b, soften_bias).rgb, detail_soften);
	vec3 c = mix(a, b, smoothstep(0.3, 0.7, m.r));
	c = mix(c, c * dry_tint.rgb, smoothstep(0.35, 0.85, m.g) * dry_amount);
	c *= 1.0 + (m.b - 0.5) * 2.0 * value_amount;
	float big = texture(blend_mask, p / patch_units + vec2(0.21, 0.43)).b;
	vec3 patch_tint = mix(patch_dark.rgb, patch_light.rgb, smoothstep(0.2, 0.8, big));
	c *= mix(vec3(1.0), patch_tint, patch_amount * 4.0);
	c *= tint.rgb;
	c *= mix(1.0, COLOR.g, vertex_ao);
	float air = sn_air(v_world, CAMERA_POSITION_WORLD, air_strength, air_start, air_distance);
	ALBEDO = c * (1.0 - air);
	EMISSION += air_color.rgb * air;
	ROUGHNESS = 1.0;
}

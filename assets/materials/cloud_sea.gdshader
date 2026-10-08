shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
// Mar de nuvens visto de cima (spec 012, Fase 3; arte A08 sky/cloud_sea, seamless): plano bem abaixo da ilha,
// duas camadas em escalas diferentes que andam devagar por TIME, apagando longe do centro (o céu de baixo
// continua aparecendo nas bordas). A névoa de altura da cena esfria o resto.

uniform sampler2D sea : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tile_units = 48.0;
uniform vec2 drift = vec2(0.25, 0.1);
uniform vec4 tint : source_color = vec4(0.6, 0.64, 0.84, 1.0);
uniform float energy = 1.0;
// Raio (horizontal) em que o mar começa e termina de sumir.
uniform vec2 fade_radius = vec2(90.0, 170.0);
uniform float opacity = 0.95;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_world.xz;
	vec4 a = texture(sea, p / tile_units + drift * TIME * 0.01);
	vec4 b = texture(sea, vec2(-p.y, p.x) / (tile_units * 0.57) + vec2(0.37, 0.61) - drift.yx * TIME * 0.013);
	vec3 c = mix(a.rgb, b.rgb, 0.4) * tint.rgb;
	ALBEDO = c * energy;
	float r = length(p);
	ALPHA = opacity * (1.0 - smoothstep(fade_radius.x, fade_radius.y, r));
}

shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;
// Nuvem PROVISÓRIA (spec 012, Fase 1): aglomerados de esferas achatadas. Topo branco-quente,
// base lavanda, mais claro do lado do sol. Os puffs pintados da A08 entram na Fase 3.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 color_top : source_color = vec4(0.965, 0.933, 0.902, 1.0);
uniform vec4 color_side : source_color = vec4(0.886, 0.847, 0.878, 1.0);
uniform vec4 color_base : source_color = vec4(0.737, 0.698, 0.784, 1.0);
uniform vec4 color_deep : source_color = vec4(0.612, 0.612, 0.722, 1.0);
// Direção de onde vem o sol (no mundo), para clarear o lado iluminado.
uniform vec3 sun_from = vec3(-0.64, 0.7, -0.3);
uniform float sun_boost = 0.06;
// Abaixo desta altura a nuvem fica mais funda (mar de nuvens).
uniform vec2 depth_range = vec2(-34.0, -6.0);

varying vec3 v_world;
varying vec3 v_nrm;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_nrm + (vec3(sn_noise3(v_world * 0.6), sn_noise3(v_world * 0.6 + 5.0), sn_noise3(v_world * 0.6 + 9.0)) - 0.5) * 0.5);
	float up = n.y;
	vec3 c = up > 0.0 ? mix(color_side.rgb, color_top.rgb, smoothstep(0.0, 0.7, up)) : mix(color_side.rgb, color_base.rgb, smoothstep(0.0, 0.8, -up));
	float lit = clamp(dot(n, normalize(sun_from)), 0.0, 1.0);
	c += vec3(1.0, 0.94, 0.85) * lit * sun_boost;
	float deep = 1.0 - clamp((v_world.y - depth_range.x) / (depth_range.y - depth_range.x), 0.0, 1.0);
	c = mix(c, color_deep.rgb, deep * 0.45 * (1.0 - smoothstep(0.2, 0.9, up)));
	ALBEDO = c;
}

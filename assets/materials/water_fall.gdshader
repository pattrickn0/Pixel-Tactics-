shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque, shadows_disabled;
// Lâmina de cascata PROVISÓRIA (spec 012, Fase 1): riscos verticais rolando por TIME, mais claros no
// meio, espuma branca na quina e bordas se desfazendo. UV: x ao longo da lâmina (unidades), y para baixo
// a partir da quina (unidades). Os riscos pintados da A08 entram na Fase 3.

#include "res://assets/materials/scenery_noise.gdshaderinc"

uniform vec4 color_deep : source_color = vec4(0.353, 0.494, 0.612, 1.0);
uniform vec4 color_mid : source_color = vec4(0.498, 0.635, 0.745, 1.0);
uniform vec4 color_light : source_color = vec4(0.714, 0.816, 0.890, 1.0);
uniform vec4 color_foam : source_color = vec4(0.918, 0.965, 0.988, 1.0);
// Velocidade da queda (unidades por segundo). A largura de cada lâmina e a altura da queda vêm da cor do
// vértice (r = largura / 32, g = altura / 32), para cada lâmina apagar as próprias bordas.
uniform float fall_speed = 3.0;

void fragment() {
	vec2 p = UV;
	float sheet_width = COLOR.r * 32.0;
	float fall_height = COLOR.g * 32.0;
	float streak = sn_noise2(vec2(p.x * 2.2, p.y * 0.12 - TIME * fall_speed * 0.12));
	float fine = sn_noise2(vec2(p.x * 7.0, p.y * 0.35 - TIME * fall_speed * 0.35));
	float v = streak * 0.65 + fine * 0.35;
	vec3 c = mix(color_mid.rgb, color_light.rgb, smoothstep(0.35, 0.75, v));
	c = mix(c, color_deep.rgb, smoothstep(0.35, 0.1, v) * 0.5);
	// Espuma na quina (primeiras unidades) e embaixo, onde vira névoa.
	float foam = smoothstep(1.4, 0.0, p.y) + smoothstep(fall_height * 0.7, fall_height, p.y);
	c = mix(c, color_foam.rgb, clamp(foam + smoothstep(0.7, 0.95, fine) * 0.4, 0.0, 1.0));
	float edge = min(p.x, sheet_width - p.x);
	float a = smoothstep(0.0, 0.8, edge + (fine - 0.5) * 0.8);
	a *= 1.0 - smoothstep(fall_height * 0.82, fall_height, p.y) * 0.85;
	ALBEDO = c * 1.05;
	ALPHA = clamp(a * 0.92, 0.0, 1.0);
}

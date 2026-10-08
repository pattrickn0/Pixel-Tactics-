shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque, shadows_disabled;
// Lâmina de cascata pintada (spec 012, Fase 3; arte A08: water/fall_streaks, 4 x 8 unidades, e water/fall_foam,
// 8 x 2 unidades, seamless em u). Os riscos rolam para baixo por TIME (duas camadas em velocidades diferentes),
// a espuma fica presa na quina (v = 0 do fall_foam) e a lâmina se desfaz embaixo, na névoa.
// UV: x ao longo da lâmina (unidades), y para baixo a partir do começo do rio (unidades). COLOR.r = largura / 32,
// COLOR.g = altura da queda / 32 (cada lâmina apaga as próprias bordas).

uniform sampler2D streaks : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D foam : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 streak_units = vec2(4.0, 8.0);
uniform vec2 foam_units = vec2(8.0, 2.0);
// Velocidade da queda (unidades por segundo).
uniform float fall_speed = 3.0;
// Distância (UV.y) da quina, onde a espuma começa.
uniform float foam_start = 0.35;
uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 1.12;

void fragment() {
	vec2 p = UV;
	float sheet_width = COLOR.r * 32.0;
	float fall_height = COLOR.g * 32.0;
	vec3 c = texture(streaks, vec2(p.x / streak_units.x, (p.y - TIME * fall_speed) / streak_units.y)).rgb;
	vec3 c2 = texture(streaks, vec2(p.x / streak_units.x * 1.7 + 0.37, (p.y - TIME * fall_speed * 1.6) / (streak_units.y * 0.77))).rgb;
	c = mix(c, c2, 0.35);
	float fv = (p.y - foam_start) / foam_units.y;
	vec4 f = texture(foam, vec2(p.x / foam_units.x, clamp(fv, 0.001, 0.999)));
	f.a *= step(0.0, fv) * step(fv, 1.0);
	c = mix(c, f.rgb, f.a);
	float edge = min(p.x, sheet_width - p.x);
	float a = smoothstep(0.0, 0.6, edge);
	a *= 1.0 - smoothstep(fall_height * 0.72, fall_height, p.y) * 0.9;
	ALBEDO = c * tint.rgb * energy;
	ALPHA = clamp(a, 0.0, 1.0);
}

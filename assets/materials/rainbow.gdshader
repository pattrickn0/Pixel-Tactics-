shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled, fog_disabled;
// Arco-íris (spec 012, Fase 3; arte A08 fx/rainbow: v = 0 borda de fora/vermelho, v = 1 de dentro/violeta): fita
// em arco, aditiva e fraca, apagando nas pontas. Só aparece com a câmera na metade sul da órbita (z > 0).
// UV: x ao longo do arco (0..1), y através das faixas.

uniform sampler2D bands : source_color, filter_linear, repeat_disable;
uniform float intensity = 0.55;

void fragment() {
	vec4 t = texture(bands, vec2(clamp(UV.x, 0.01, 0.99), clamp(UV.y, 0.02, 0.98)));
	float ends = smoothstep(0.0, 0.25, UV.x) * smoothstep(1.0, 0.7, UV.x);
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float south = smoothstep(-6.0, 6.0, cam.z);
	ALBEDO = t.rgb * t.a * intensity * ends * south;
}

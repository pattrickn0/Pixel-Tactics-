shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled, fog_disabled;
// Arco-íris PROVISÓRIO (spec 012, Fase 1): fita em arco com 6 faixas suaves, aditiva e fraca,
// apagando nas pontas. Só aparece com a câmera na metade sul da órbita (z > 0).
// UV: x ao longo do arco (0..1), y através das faixas (0 = fora/vermelho, 1 = dentro/violeta).

uniform float intensity = 0.55;

void fragment() {
	vec3 bands[6] = vec3[6](vec3(0.95, 0.35, 0.35), vec3(0.98, 0.62, 0.30), vec3(0.98, 0.92, 0.42),
			vec3(0.45, 0.88, 0.45), vec3(0.40, 0.62, 0.98), vec3(0.62, 0.45, 0.92));
	float t = clamp(UV.y, 0.0, 0.999) * 5.0;
	int i = int(floor(t));
	vec3 c = mix(bands[i], bands[min(i + 1, 5)], fract(t));
	float across = sin(clamp(UV.y, 0.0, 1.0) * 3.14159);
	float ends = smoothstep(0.0, 0.25, UV.x) * smoothstep(1.0, 0.7, UV.x);
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float south = smoothstep(-6.0, 6.0, cam.z);
	ALBEDO = c * intensity * across * ends * south;
}

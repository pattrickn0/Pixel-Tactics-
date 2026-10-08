shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// Feixes de luz bem fracos sobre a mata do noroeste (direção de arte: opcional, no máximo 3, nunca sobre a
// arena). Fita aditiva quente, apagando nas bordas, nas pontas, quando vista de lado e perto da geometria
// (sem linha dura onde cruza a copa). UV: x de uma borda à outra (0..1), y do céu (0) até a copa (1).

uniform vec4 shaft_color : source_color = vec4(1.0, 0.84, 0.55, 1.0);
uniform float intensity = 0.22;
// Distância (unidades) em que o feixe some ao encostar na geometria.
uniform float proximity_fade = 1.5;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;

void fragment() {
	float across = sin(UV.x * 3.14159265);
	float along = smoothstep(0.0, 0.45, UV.y) * (1.0 - smoothstep(0.9, 1.0, UV.y));
	// Visto de lado, a fita vira uma linha: apaga.
	float facing = smoothstep(0.15, 0.6, abs(dot(NORMAL, VIEW)));
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 world = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = -world.z / world.w;
	float near = clamp((scene_z + VERTEX.z) / proximity_fade, 0.0, 1.0);
	// Com a câmera perto do feixe (outras vistas da órbita), ele some.
	float far_enough = smoothstep(12.0, 28.0, -VERTEX.z);
	float a = across * across * along * facing * near * far_enough * intensity;
	ALBEDO = shaft_color.rgb * a;
}

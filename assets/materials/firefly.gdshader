shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled, skip_vertex_transform;
// Vaga-lumes (spec 012, Fase 3): MultiMesh de quads em billboard, posições em tabela (IslandTables.FIREFLIES).
// Cada um flutua e pisca devagar só por TIME e pelo número da instância (sem sorteio). Emissivo dourado.
// Malha: quad com cantos (±1, ±1) no plano XY.

uniform vec4 color : source_color = vec4(1.0, 0.855, 0.506, 1.0);
uniform float energy = 3.0;
uniform float size = 0.14;
uniform float drift = 0.25;

varying float v_pulse;

void vertex() {
	float id = float(INSTANCE_ID);
	vec3 d = vec3(sin(TIME * 0.7 + id * 1.3), sin(TIME * 0.9 + id * 2.1) * 0.6, cos(TIME * 0.6 + id * 0.7)) * drift;
	vec3 cv = (MODELVIEW_MATRIX * vec4(d, 1.0)).xyz;
	// Longe (cascata), cresce com a distância para não sumir abaixo de 1 pixel.
	VERTEX = cv + vec3(VERTEX.xy * size * max(1.0, -cv.z / 35.0), 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_pulse = 0.55 + 0.45 * sin(TIME * 1.9 + id * 2.7);
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float a = pow(1.0 - smoothstep(0.0, 1.0, r), 2.0);
	ALBEDO = color.rgb * energy * v_pulse * a;
}

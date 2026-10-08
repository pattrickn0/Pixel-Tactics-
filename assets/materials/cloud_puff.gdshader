shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never, shadows_disabled, skip_vertex_transform, ambient_light_disabled, specular_disabled, fog_disabled;
// Puffs de nuvem e de névoa pintados (spec 012, Fase 3; arte A08: sky/cloud_puffs atlas 2x2 e fx/mist_puff), em
// billboard: cada puff é um quad montado no plano XY local da peça e virado para a câmera no vertex() em volta do
// próprio centro. UV = célula do atlas (com uma folga mínima), e daí sai o canto do quad; COLOR.r = meia largura / 32.
// Alfa suave, sem sombra. Cada aglomerado (peça) é um objeto: a transparência é ordenada por aglomerado.
// As nuvens mais baixas (mar de nuvens) ficam mais fundas: lavanda mais escura, na base de cada puff mais que no topo.
// A cor vai na emissão (não depende da luz); o light() só soma um brilho quente nos puffs vistos contra o sol
// (a direção vem do próprio sol da cena: nenhuma constante de direção aqui).

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform int atlas_cols = 2;
uniform int atlas_rows = 2;
uniform vec4 tint : source_color = vec4(1.0);
// Brilho acima de 1 (unshaded): o topo chega a branco quente depois do tonemap.
uniform float energy = 1.0;
uniform vec4 deep_tint : source_color = vec4(0.4, 0.4, 0.55, 1.0);
uniform vec2 depth_range = vec2(-18.0, -3.0);
uniform float deep_amount = 0.9;
uniform float alpha_scale = 1.0;
// Topo do puff mais claro (chega a branco quente; a base fica lavanda).
uniform float top_boost = 0.15;
// Brilho quente do lado do sol (espalhamento para a frente).
uniform vec4 sun_tint : source_color = vec4(1.0, 0.66, 0.44, 1.0);
uniform float sun_amount = 1.0;

varying float v_deep;

void vertex() {
	vec2 cells = vec2(float(atlas_cols), float(atlas_rows));
	vec2 corner = step(vec2(0.5), fract(UV * cells));
	float half_size = COLOR.r * 32.0;
	vec2 off = vec2(corner.x * 2.0 - 1.0, 1.0 - corner.y * 2.0) * half_size;
	vec3 center = VERTEX - vec3(off, 0.0);
	float scale = length(MODEL_MATRIX[0].xyz);
	VERTEX = (MODELVIEW_MATRIX * vec4(center, 1.0)).xyz + vec3(off * scale, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	float wy = (MODEL_MATRIX * vec4(center, 1.0)).y;
	v_deep = 1.0 - clamp((wy - depth_range.x) / (depth_range.y - depth_range.x), 0.0, 1.0);
}

void fragment() {
	vec4 t = texture(atlas, UV);
	vec3 c = t.rgb * tint.rgb;
	float cell_v = fract(UV.y * float(atlas_rows));
	float base = smoothstep(0.3, 0.75, cell_v);
	c = mix(c, c * deep_tint.rgb, v_deep * deep_amount * (0.35 + 0.65 * base));
	c *= energy * mix(0.94, 1.04, COLOR.a) * (1.0 + top_boost * (1.0 - base));
	EMISSION = c;
	ALBEDO = c * sun_amount * (1.0 - base * 0.6);
	ALPHA = clamp(t.a * alpha_scale, 0.0, 1.0);
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		// Olhando na direção do sol (VIEW aponta para a câmera): o puff esquenta.
		float toward = clamp(dot(-VIEW, LIGHT), 0.0, 1.0);
		DIFFUSE_LIGHT += sun_tint.rgb * (0.25 + 0.75 * toward * toward) * LIGHT_COLOR / PI;
	}
}

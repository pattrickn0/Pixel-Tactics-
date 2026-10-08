shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
// Chama dos braseiros (spec 012, Fase 3; arte A08 fx/fire_flipbook: 4 quadros de 128 x 192 lado a lado, pé da
// chama em v ~ 0,93, em laço). Flipbook por TIME, com a fase pela posição do braseiro (sem sorteio). Emissiva:
// passa do limiar do glow.

uniform sampler2D flipbook : source_color, filter_linear_mipmap, repeat_disable;
uniform int frames = 4;
// Quadros por segundo do flipbook.
uniform float fps = 8.0;
uniform float energy = 2.4;

varying float v_phase;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	v_phase = floor(fract(dot(w.xz, vec2(0.37, 0.61))) * 4.0);
}

void fragment() {
	float f = mod(floor(TIME * fps) + v_phase, float(frames));
	vec2 uv = vec2((f + clamp(UV.x, 0.004, 0.996)) / float(frames), UV.y);
	vec4 t = texture(flipbook, uv);
	ALBEDO = t.rgb * energy;
	ALPHA = t.a;
}

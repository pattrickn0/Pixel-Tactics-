shader_type sky;
// Céu de dia claro PROVISÓRIO (spec 012, Fase 1): zênite azul-lavanda, meio claro, horizonte rosado e
// o "céu de baixo" claro (a câmera olha para baixo e ele aparece entre as nuvens). Mais quente perto do sol.

uniform vec4 zenith : source_color = vec4(0.561, 0.690, 0.847, 1.0);
uniform vec4 middle : source_color = vec4(0.788, 0.827, 0.918, 1.0);
uniform vec4 horizon : source_color = vec4(0.918, 0.851, 0.863, 1.0);
uniform vec4 below : source_color = vec4(0.773, 0.792, 0.886, 1.0);
uniform vec4 sun_glow : source_color = vec4(1.0, 0.941, 0.847, 1.0);
uniform float sun_glow_size = 0.35;
uniform float energy = 1.0;

void sky() {
	float y = EYEDIR.y;
	vec3 c;
	if (y >= 0.0) {
		c = mix(horizon.rgb, middle.rgb, smoothstep(0.0, 0.25, y));
		c = mix(c, zenith.rgb, smoothstep(0.25, 0.85, y));
	} else {
		c = mix(horizon.rgb, below.rgb, smoothstep(0.0, -0.45, y));
	}
	if (LIGHT0_ENABLED) {
		float s = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		c = mix(c, sun_glow.rgb, pow(s, 1.0 / max(sun_glow_size, 0.01) * 2.0) * 0.8);
		// Lado do sol mais quente em toda a faixa do horizonte (inclusive abaixo dele).
		vec2 eh = normalize(EYEDIR.xz + vec2(0.0001));
		vec2 sh = normalize(LIGHT0_DIRECTION.xz + vec2(0.0001));
		float side = pow(clamp(dot(eh, sh) * 0.5 + 0.5, 0.0, 1.0), 3.0);
		c = mix(c, sun_glow.rgb, side * 0.45 * (1.0 - smoothstep(0.3, 0.8, abs(y))));
	}
	COLOR = c * energy;
}

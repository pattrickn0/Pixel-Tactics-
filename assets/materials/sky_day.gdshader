shader_type sky;
// Céu de dia claro (spec 012, revisão f2): zênite azul-lavanda, meio claro, horizonte rosado e o "céu de baixo"
// claro (a câmera olha para baixo: o topo do quadro já fica um pouco abaixo do horizonte). Do lado do sol, a faixa
// do horizonte esquenta. As cores estão em LINEAR, já compensando o tonemap (Filmic, branco 3, exposição 1,25):
// assim o quadro chega às cores medidas na referência (caixas "céu alto" da spec) e o branco chega a branco.

uniform vec3 zenith = vec3(0.181, 0.32, 0.702);
uniform vec3 middle = vec3(0.511, 0.629, 1.108);
uniform vec3 horizon = vec3(1.108, 0.718, 0.77);
// Logo abaixo do horizonte (topo do quadro na câmera padrão) e mais para baixo (entre as nuvens, sob a ilha).
uniform vec3 below_near = vec3(0.26, 0.32, 0.85);
uniform vec3 below = vec3(0.255, 0.332, 0.615);
// Lado do sol (perto do horizonte) e brilho em volta do sol.
uniform vec3 warm_side = vec3(1.0, 0.54, 0.33);
uniform vec3 sun_glow = vec3(2.2, 1.33, 0.702);
uniform float sun_glow_size = 0.35;
uniform float warm_amount = 0.95;
uniform float energy = 1.0;

void sky() {
	float y = EYEDIR.y;
	vec3 c;
	if (y >= 0.0) {
		c = mix(horizon, middle, smoothstep(0.0, 0.25, y));
		c = mix(c, zenith, smoothstep(0.25, 0.85, y));
	} else {
		c = mix(horizon, below_near, smoothstep(0.0, -0.1, y));
		c = mix(c, below, smoothstep(-0.15, -0.6, y));
	}
	if (LIGHT0_ENABLED) {
		// Lado do sol mais quente em toda a faixa do horizonte (inclusive abaixo dele).
		vec2 eh = normalize(EYEDIR.xz + vec2(0.0001));
		vec2 sh = normalize(LIGHT0_DIRECTION.xz + vec2(0.0001));
		float side = smoothstep(-0.1, 0.85, dot(eh, sh));
		c = mix(c, warm_side, side * warm_amount * (1.0 - smoothstep(0.25, 0.7, abs(y))));
		float s = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		c = mix(c, sun_glow, pow(s, 1.0 / max(sun_glow_size, 0.01) * 2.0) * 0.8);
	}
	COLOR = c * energy;
}

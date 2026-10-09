shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_always, fog_disabled, shadows_disabled, specular_disabled, ambient_light_disabled;
// Nuvem volumétrica (spec 013): raymarch próprio dentro de um volume-proxy (caixa desenhada por dentro, funciona
// com a câmera dentro). A densidade é a união suave dos lóbulos da massa (elipsoides em espaço local, tabela
// tools/kit/cloud_tables.gd) erodida por ruído 3D procedural (hash de constantes fixas). Cada amostra calcula a luz
// do sol com transmitância (Beer, marcha até o sol), fase Henyey-Greenstein dupla (forro de prata) e "powder", mais
// um ambiente por altura; o escalar de luz resultante passa por uma rampa de cor de tela (5 tons medidos na
// referência). A rampa é cor de TELA: o shader desfaz o tonemap Filmic (inversa exata da curva) para a captura
// chegar nela. A marcha para na profundidade da cena (abraça penhasco e ilhotas). Perspectiva aérea própria (sem a
// névoa da cena). A direção do sol vem só do uniform global publicado a partir do nó Sun (SkyGlobals).

const int MAX_LOBES = 32;
const int LIGHT_STEPS = 6;

// ---- globais (project.godot, publicados por scripts/core/sky_globals.gd)
global uniform vec3 sun_direction;
global uniform vec4 sun_color;
global uniform float sun_energy;
global uniform float cloud_time;
global uniform sampler2D island_shadow_mask;
global uniform vec4 island_shadow_rect;

// ---- forma (por massa, da tabela)
uniform vec4 lobes[32];
uniform vec3 lobe_axes[32];
uniform int lobe_count = 0;
// Camada (mar de nuvens): topo ondulado em vez de lóbulos (layer_mode = true).
uniform bool layer_mode = false;
uniform float layer_top = -20.0;
uniform float layer_amp = 3.0;
uniform float layer_cell = 14.0;
uniform vec3 proxy_min = vec3(-10.0);
uniform vec3 proxy_max = vec3(10.0);
// Mistura entre lóbulos (união suave) e maciez da borda (unidades).
uniform float blend_k = 1.2;
uniform float edge_softness = 0.4;
// Base que some (y local) e topo da massa (para a altura relativa).
uniform float base_height = -6.0;
uniform float base_softness = 2.0;
uniform float top_height = 4.0;
uniform float density = 1.2;
// Ruído: escala (ciclos por unidade), força (deslocamento da superfície, unidades) e erosão por altura
// (mais na base e nas bordas, menos na crista).
uniform float noise_scale = 0.24;
uniform float noise_strength = 1.6;
uniform float erosion_base = 1.4;
uniform float erosion_top = 0.6;
uniform vec3 noise_offset = vec3(0.0);
uniform float drift_speed = 0.12;
// Peso de cada oitava menor das bolotas.
uniform float puff_gain = 0.45;
// Centro do ruído: abaixo dele a superfície afunda, acima cresce.
uniform float puff_bias = 0.5;

// ---- luz
uniform int primary_steps : hint_range(16, 192) = 128;
uniform float extinction = 3.0;
uniform float light_extinction = 0.45;
uniform float light_step = 0.6;
uniform float light_growth = 1.55;
uniform float sun_strength = 1.3;
uniform float phase_forward = 0.6;
uniform float phase_back = -0.2;
uniform float phase_mix = 0.5;
uniform float powder_strength = 0.5;
uniform float ms_floor = 0.2;
// Ambiente: luz do céu de cima, atenuada pela nuvem acima da amostra (3 amostras para cima) e pela altura na massa.
uniform float ambient_bottom = 0.05;
uniform float ambient_top = 0.45;
uniform float ambient_extinction = 0.5;
uniform float ambient_height_mix = 0.5;

// ---- cor (rampa de tela, Tabela N2 "Todas"; linha da sombra da ilha, M8)
uniform float light_lo = 0.25;
uniform float light_hi = 2.0;
uniform float light_gamma = 1.0;
// Exposição da massa (multiplica o escalar de luz antes da rampa; calibração por massa, na tabela).
uniform float exposure = 1.0;
uniform vec4 ramp_p5 : source_color = vec4(0.584, 0.624, 0.710, 1.0);
uniform vec4 ramp_p25 : source_color = vec4(0.706, 0.686, 0.749, 1.0);
uniform vec4 ramp_p50 : source_color = vec4(0.839, 0.769, 0.773, 1.0);
uniform vec4 ramp_p75 : source_color = vec4(0.929, 0.851, 0.812, 1.0);
uniform vec4 ramp_p95 : source_color = vec4(0.992, 0.933, 0.839, 1.0);
uniform vec4 shadow_p5 : source_color = vec4(0.506, 0.522, 0.592, 1.0);
uniform vec4 shadow_p50 : source_color = vec4(0.553, 0.592, 0.678, 1.0);
uniform vec4 shadow_p95 : source_color = vec4(0.624, 0.639, 0.714, 1.0);
uniform float island_shadow_strength = 0.85;
uniform float island_shadow_plane = 0.0;
// Penumbra da sombra da ilha: largura base e quanto cresce por unidade de distância até a ilha.
uniform float island_shadow_penumbra = 1.5;
uniform float island_shadow_spread = 0.12;
// Perspectiva aérea própria: no máximo aerial_max em direção a aerial_color a aerial_distance.
uniform vec4 aerial_color : source_color = vec4(0.863, 0.839, 0.902, 1.0);
uniform float aerial_max = 0.15;
uniform float aerial_distance = 200.0;
uniform float opacity = 1.0;
// Alfa mínimo para a nuvem escrever a profundidade dela (abaixo disso, fica a profundidade do céu).
uniform float depth_alpha = 0.35;
// Desfaz o tonemap Filmic do WorldEnvironment (exposição e branco iguais aos da cena).
uniform bool compensate_tonemap = true;
uniform float tonemap_exposure = 1.25;
uniform float tonemap_white = 3.0;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 v_local;
varying vec3 v_cam_local;
varying vec3 v_sun_local;
varying vec3 v_up_local;
varying float v_scale;

// ---------------------------------------------------------------- ruído (hash de constantes fixas)
float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y), mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

// Ruído "billow" (bolotas redondas com vales estreitos), de 0 a 1.
float billow(vec3 p, int octaves) {
	float sum = 0.0;
	float amp = 0.5;
	float norm = 0.0;
	for (int o = 0; o < 3; o++) {
		if (o >= octaves) {
			break;
		}
		float n = value_noise(p);
		sum += amp * (1.0 - abs(2.0 * n - 1.0));
		norm += amp;
		amp *= 0.5;
		p = p * 2.03 + vec3(17.1, 5.3, 11.7);
	}
	return sum / norm;
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

// Distância até o ponto de célula mais próximo (Worley F1), de 0 a ~1.
float worley(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d = 9.0;
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 c = vec3(float(x), float(y), float(z));
				vec3 r = c + hash33(i + c) - f;
				d = min(d, dot(r, r));
			}
		}
	}
	return sqrt(d);
}

// Bolotas (couve-flor): Worley invertido, cada célula vira um domo redondo; oitavas menores na borda. De 0 a 1.
float puffs(vec3 p, int octaves) {
	float sum = 0.0;
	float amp = 0.6;
	float norm = 0.0;
	for (int o = 0; o < 3; o++) {
		if (o >= octaves) {
			break;
		}
		sum += amp * clamp(1.0 - worley(p), 0.0, 1.0);
		norm += amp;
		amp *= puff_gain;
		p = p * 2.07 + vec3(17.1, 5.3, 11.7);
	}
	return sum / norm;
}

// ---------------------------------------------------------------- forma
float smin(float a, float b, float k) {
	float h = max(k - abs(a - b), 0.0) / k;
	return min(a, b) - h * h * k * 0.25;
}

// Distância (aproximada) até a superfície da união dos lóbulos (negativa dentro).
float shape_sd(vec3 p) {
	if (layer_mode) {
		// Topo ondulado em cúmulos: bolotas de célula layer_cell.
		float w = billow(vec3(p.x, 0.0, p.z) / layer_cell + noise_offset, 2);
		return p.y - (layer_top + layer_amp * (w - 0.5) * 2.0);
	}
	float d = 1e5;
	for (int i = 0; i < MAX_LOBES; i++) {
		if (i >= lobe_count) {
			break;
		}
		vec3 r = max(lobes[i].w * lobe_axes[i], vec3(0.05));
		vec3 q = p - lobes[i].xyz;
		float k0 = length(q / r);
		float k1 = length(q / (r * r));
		float di = k0 * (k0 - 1.0) / max(k1, 1e-4);
		d = smin(d, di, blend_k);
	}
	return d;
}

float height01(vec3 p) {
	return clamp((p.y - base_height) / max(top_height - base_height, 0.01), 0.0, 1.0);
}

// Densidade a partir da distância já calculada (octaves: menos na marcha de luz).
float density_from(vec3 p, float sd, int octaves) {
	float h = height01(p);
	float ero = noise_strength * mix(erosion_base, erosion_top, h);
	vec3 np = p * noise_scale + noise_offset + vec3(cloud_time * drift_speed * noise_scale, 0.0, cloud_time * drift_speed * 0.5 * noise_scale);
	float n = puffs(np, octaves);
	float s = sd + ero * (puff_bias - n) * 2.0;
	float d = smoothstep(0.0, edge_softness, -s);
	d *= smoothstep(base_height - base_softness, base_height + base_softness, p.y);
	return d * density;
}

// ---------------------------------------------------------------- luz
float hg(float c, float g) {
	float g2 = g * g;
	return (1.0 - g2) / pow(max(1.0 + g2 - 2.0 * g * c, 1e-4), 1.5);
}

// Inversa da curva Filmic do Godot (tonemap_filmic com exposure_bias 2): resolve a quadrática por canal.
float filmic_inv(float y, float white) {
	const float FA = 0.22 * 4.0;
	const float FB = 0.30 * 2.0;
	const float FC = 0.10;
	const float FD = 0.20;
	const float FE = 0.01;
	const float FF = 0.30;
	float wt = ((white * (FA * white + FC * FB) + FD * FE) / (white * (FA * white + FB) + FD * FF)) - FE / FF;
	float yy = clamp(y, 0.0, 0.995) * wt + FE / FF;
	// FA x^2 (yy - 1) + FB x (yy - FC) + FD (FF yy - FE) = 0
	float qa = FA * (yy - 1.0);
	float qb = FB * (yy - FC);
	float qc = FD * (FF * yy - FE);
	float disc = max(qb * qb - 4.0 * qa * qc, 0.0);
	return (-qb - sqrt(disc)) / (2.0 * qa);
}

vec3 untonemap(vec3 c) {
	return vec3(filmic_inv(c.r, tonemap_white), filmic_inv(c.g, tonemap_white), filmic_inv(c.b, tonemap_white)) / tonemap_exposure;
}

vec3 ramp5(float x, vec3 a, vec3 b, vec3 c, vec3 d, vec3 e) {
	// Paradas em 0,05 / 0,25 / 0,50 / 0,75 / 0,95 (P5 ... P95).
	if (x < 0.25) {
		return mix(a, b, clamp((x - 0.05) / 0.2, 0.0, 1.0));
	} else if (x < 0.5) {
		return mix(b, c, (x - 0.25) / 0.25);
	} else if (x < 0.75) {
		return mix(c, d, (x - 0.5) / 0.25);
	}
	return mix(d, e, clamp((x - 0.75) / 0.2, 0.0, 1.0));
}

vec3 ramp3(float x, vec3 a, vec3 c, vec3 e) {
	if (x < 0.5) {
		return mix(a, c, clamp((x - 0.05) / 0.45, 0.0, 1.0));
	}
	return mix(c, e, clamp((x - 0.5) / 0.45, 0.0, 1.0));
}

float island_shadow(vec3 wp) {
	// Projeta a amostra na direção do sol até o plano da ilha e lê a pegada vista de cima.
	if (sun_direction.y <= 0.01 || wp.y >= island_shadow_plane) {
		return 0.0;
	}
	float t = (island_shadow_plane - wp.y) / sun_direction.y;
	vec3 hit = wp + sun_direction * t;
	vec2 size = island_shadow_rect.zw - island_shadow_rect.xy;
	vec2 uv = (hit.xz - island_shadow_rect.xy) / size;
	if (uv.x <= 0.0 || uv.y <= 0.0 || uv.x >= 1.0 || uv.y >= 1.0) {
		return 0.0;
	}
	// Penumbra cresce com a distância até a ilha (mipmap da máscara).
	float texel = size.x / float(textureSize(island_shadow_mask, 0).x);
	float lod = log2(max((island_shadow_penumbra + island_shadow_spread * t) / texel, 1.0));
	return textureLod(island_shadow_mask, uv, lod).r;
}

void vertex() {
	v_local = VERTEX;
	mat4 inv_model = inverse(MODEL_MATRIX);
	v_cam_local = (inv_model * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	v_sun_local = normalize(mat3(inv_model) * sun_direction);
	v_up_local = normalize(mat3(inv_model) * vec3(0.0, 1.0, 0.0));
	v_scale = length(MODEL_MATRIX[0].xyz);
}

void fragment() {
	vec3 ro = v_cam_local;
	vec3 rd = normalize(v_local - v_cam_local);
	// Entrada e saída da caixa do proxy.
	vec3 inv = 1.0 / rd;
	vec3 ta = (proxy_min - ro) * inv;
	vec3 tb = (proxy_max - ro) * inv;
	vec3 tlo = min(ta, tb);
	vec3 thi = max(ta, tb);
	float t0 = max(max(max(tlo.x, tlo.y), tlo.z), 0.0);
	float t1 = min(min(thi.x, thi.y), thi.z);
	// Para na profundidade da cena.
	float depth = texture(depth_tex, SCREEN_UV).r;
	if (depth > 0.0) {
		vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
		view.xyz /= view.w;
		t1 = min(t1, length(view.xyz) / v_scale);
	}
	if (t1 <= t0) {
		discard;
	}
	vec3 wsun = normalize(sun_direction);
	vec3 wrd = normalize(mat3(MODEL_MATRIX) * rd);
	float cos_t = dot(wrd, wsun);
	float phase = mix(hg(cos_t, phase_forward), hg(cos_t, phase_back), phase_mix);
	float sun_e = sun_energy * sun_strength * dot(sun_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 lsun = v_sun_local;

	float base_dt = max((t1 - t0) / float(primary_steps), edge_softness * 0.35);
	// Deslocamento por pixel (ruído de gradiente intercalado, fórmula fixa): troca faixas de passo por grão fino.
	float jitter = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	float t = t0 + base_dt * jitter;
	float trans = 1.0;
	float acc = 0.0;
	float acc_t = 0.0;
	float acc_sh = 0.0;
	for (int i = 0; i < 192; i++) {
		if (i >= primary_steps * 2 || t >= t1 || trans < 0.01) {
			break;
		}
		vec3 p = ro + rd * t;
		float sd = shape_sd(p);
		float margin = noise_strength * erosion_base + edge_softness;
		if (sd > margin) {
			// Espaço vazio: anda pela distância até os lóbulos.
			t += max(sd - margin, base_dt);
			continue;
		}
		float d = density_from(p, sd, 3);
		if (d > 0.002) {
			// Marcha até o sol (passos crescentes).
			float od = 0.0;
			float lt = 0.0;
			float seg = light_step;
			for (int j = 0; j < LIGHT_STEPS; j++) {
				lt += seg * 0.5;
				vec3 q = p + lsun * lt;
				od += density_from(q, shape_sd(q), 1) * seg;
				lt += seg * 0.5;
				seg *= light_growth;
			}
			od *= v_scale * light_extinction;
			float beer = max(exp(-od), ms_floor * exp(-od * 0.25));
			float powder = mix(1.0, 1.0 - exp(-2.0 * d * extinction), powder_strength);
			vec3 wp = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
			float sh = island_shadow(wp) * island_shadow_strength;
			float sun_l = sun_e * beer * phase * powder * (1.0 - sh);
			float h = height01(p);
			float od_up = 0.0;
			for (int j = 0; j < 3; j++) {
				float up = 0.6 * pow(3.0, float(j));
				vec3 q = p + v_up_local * up;
				od_up += density_from(q, shape_sd(q), 1) * up * 0.67;
			}
			float sky = exp(-od_up * v_scale * ambient_extinction) * mix(1.0, h, ambient_height_mix);
			float amb = mix(ambient_bottom, ambient_top, sky);
			float l = sun_l + amb;
			float a = 1.0 - exp(-d * extinction * base_dt * v_scale);
			acc += trans * a * l;
			acc_t += trans * a * t;
			acc_sh += trans * a * sh;
			trans *= 1.0 - a;
		}
		t += base_dt;
	}
	float alpha = 1.0 - trans;
	if (alpha < 0.003) {
		discard;
	}
	float s = acc / alpha * exposure;
	// Escala logarítmica da luz (como o olho e a pintura: a sombra abre, a luz forte comprime).
	float x = pow(clamp(log(max(s, 1e-4) / light_lo) / log(max(light_hi / light_lo, 1.001)), 0.0, 1.0), light_gamma);
	vec3 col = ramp5(x, ramp_p5.rgb, ramp_p25.rgb, ramp_p50.rgb, ramp_p75.rgb, ramp_p95.rgb);
	vec3 shc = ramp3(x, shadow_p5.rgb, shadow_p50.rgb, shadow_p95.rgb);
	col = mix(col, shc, clamp(acc_sh / alpha, 0.0, 1.0));
	float dist = (acc_t / alpha) * v_scale;
	col = mix(col, aerial_color.rgb, aerial_max * clamp(dist / aerial_distance, 0.0, 1.0));
	if (compensate_tonemap) {
		col = untonemap(col);
	}
	ALBEDO = col;
	ALPHA = clamp(alpha * opacity, 0.0, 1.0);
	// Profundidade escrita (depth_draw_always): o teste usa a profundidade da nuvem, e não a do proxy, e o
	// desfoque de fundo da cena trata a massa na distância dela (e não na do céu atrás). Borda rala: fica a do céu.
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(ro + rd * (acc_t / alpha), 1.0);
	DEPTH = alpha > depth_alpha ? clip.z / clip.w : 0.0;
}

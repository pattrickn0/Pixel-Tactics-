class_name KitMesher
extends RefCounted
## Primitivas de malha do construtor do kit (spec 011, fase 2). Acumula triângulos por chave
## de material (nome do .tres em assets/materials/) e grava numa ArrayMesh.
## Todo triângulo é orientado sozinho para a normal pedida (frente = horária vista de fora),
## então a ordem dos cantos nas chamadas não importa. Sem sorteio: só aritmética sobre tabelas.

## Texel em unidades do mundo (32 texels por unidade).
const TEXEL: float = 1.0 / 32.0

var batches: Dictionary = {}
## Transformação aplicada a tudo que for emitido (posição, giro e escala uniforme da peça).
var xf: Transform3D = Transform3D.IDENTITY


func batch(key: String) -> MeshBatch:
	if not batches.has(key):
		batches[key] = MeshBatch.new()
	return batches[key]


## Triângulo com normais por vértice (já no espaço local da peça).
func tri(key: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
		uva: Vector2 = Vector2.ZERO, uvb: Vector2 = Vector2.ZERO, uvc: Vector2 = Vector2.ZERO) -> void:
	var pa: Vector3 = xf * a
	var pb: Vector3 = xf * b
	var pc: Vector3 = xf * c
	var wa: Vector3 = (xf.basis * na).normalized()
	var wb: Vector3 = (xf.basis * nb).normalized()
	var wc: Vector3 = (xf.basis * nc).normalized()
	# (b - a) x (c - a) aponta para dentro quando a frente é horária: se aponta para fora, troca b e c.
	if (pb - pa).cross(pc - pa).dot(wa + wb + wc) > 0.0:
		var tp: Vector3 = pb
		pb = pc
		pc = tp
		var tn: Vector3 = wb
		wb = wc
		wc = tn
		var tu: Vector2 = uvb
		uvb = uvc
		uvc = tu
	var mb: MeshBatch = batch(key)
	mb.vertices.append(pa)
	mb.vertices.append(pb)
	mb.vertices.append(pc)
	mb.normals.append(wa)
	mb.normals.append(wb)
	mb.normals.append(wc)
	mb.uvs.append(uva)
	mb.uvs.append(uvb)
	mb.uvs.append(uvc)


## Triângulo de normal única (a normal pedida decide o lado visível).
func tri_flat(key: String, a: Vector3, b: Vector3, c: Vector3, n: Vector3,
		uva: Vector2 = Vector2.ZERO, uvb: Vector2 = Vector2.ZERO, uvc: Vector2 = Vector2.ZERO) -> void:
	tri(key, a, b, c, n, n, n, uva, uvb, uvc)


## Quad com cantos em ordem cíclica e normal única virada para fora.
func quad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3,
		uva: Vector2 = Vector2.ZERO, uvb: Vector2 = Vector2.ZERO, uvc: Vector2 = Vector2.ZERO,
		uvd: Vector2 = Vector2.ZERO) -> void:
	tri_flat(key, a, b, c, n, uva, uvb, uvc)
	tri_flat(key, a, c, d, n, uva, uvc, uvd)


## Retângulo horizontal virado para cima em y. v0 = v em z0 e v1 = v em z1 (UV de faixa);
## u fica em unidades do mundo.
func top(key: String, x0: float, z0: float, x1: float, z1: float, y: float, v0: float = 0.0, v1: float = 1.0) -> void:
	quad(key, Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1), Vector3.UP,
			Vector2(x0, v0), Vector2(x1, v0), Vector2(x1, v1), Vector2(x0, v1))


## Parede vertical em z = z0, de x0 a x1 e de y0 a y1, virada para sinal sgn (+1 ou -1) em Z.
func wall_z(key: String, x0: float, x1: float, y0: float, y1: float, z0: float, sgn: float) -> void:
	quad(key, Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3(0.0, 0.0, sgn),
			Vector2(x0, 1.0), Vector2(x1, 1.0), Vector2(x1, 0.0), Vector2(x0, 0.0))


## Parede vertical em x = x0, de z0 a z1 e de y0 a y1, virada para sinal sgn em X.
func wall_x(key: String, z0: float, z1: float, y0: float, y1: float, x0: float, sgn: float) -> void:
	quad(key, Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3(sgn, 0.0, 0.0),
			Vector2(z0, 1.0), Vector2(z1, 1.0), Vector2(z1, 0.0), Vector2(z0, 0.0))


## Caixa sem fundo; uma chave de material para o topo e outra para as laterais.
func box(side_key: String, top_key: String, lo: Vector3, hi: Vector3, with_sides: bool = true) -> void:
	top(top_key, lo.x, lo.z, hi.x, hi.z, hi.y)
	if with_sides:
		wall_z(side_key, lo.x, hi.x, lo.y, hi.y, lo.z, -1.0)
		wall_z(side_key, lo.x, hi.x, lo.y, hi.y, hi.z, 1.0)
		wall_x(side_key, lo.z, hi.z, lo.y, hi.y, lo.x, -1.0)
		wall_x(side_key, lo.z, hi.z, lo.y, hi.y, hi.x, 1.0)


## Polígono horizontal virado para cima (ou para baixo se facing_up for falso), em ordem cíclica.
func disc(key: String, pts: Array[Vector2], y: float, facing_up: bool = true, uv_center: Vector2 = Vector2.ZERO,
		uv_size: float = 1.0) -> void:
	var n: Vector3 = Vector3.UP if facing_up else Vector3.DOWN
	var center := Vector2.ZERO
	for p: Vector2 in pts:
		center += p
	center /= float(pts.size())
	for i in pts.size():
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[(i + 1) % pts.size()]
		tri_flat(key, Vector3(center.x, y, center.y), Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), n,
				uv_center + (center - center) / uv_size, uv_center + (p0 - center) / uv_size, uv_center + (p1 - center) / uv_size)


## Tubo reto entre p0 e p1 (raios r0 e r1), `sides` faces planas. UV: u = arco (unidades), v = ao longo (unidades).
func tube(side_key: String, cap_key: String, p0: Vector3, p1: Vector3, r0: float, r1: float, sides: int,
		cap0: bool = false, cap1: bool = true) -> void:
	var axis: Vector3 = (p1 - p0)
	var length: float = axis.length()
	var dir: Vector3 = axis / length
	var helper: Vector3 = Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	var u_vec: Vector3 = dir.cross(helper).normalized()
	var w_vec: Vector3 = dir.cross(u_vec).normalized()
	for i in sides:
		var a0: float = TAU * float(i) / float(sides)
		var a1: float = TAU * float(i + 1) / float(sides)
		var d0: Vector3 = u_vec * cos(a0) + w_vec * sin(a0)
		var d1: Vector3 = u_vec * cos(a1) + w_vec * sin(a1)
		var mid: Vector3 = ((d0 + d1) * 0.5).normalized()
		var slope: float = (r0 - r1) / maxf(length, 0.001)
		var n: Vector3 = (mid + dir * slope).normalized()
		var arc0: float = a0 * r0
		var arc1: float = a1 * r0
		quad(side_key, p0 + d0 * r0, p0 + d1 * r0, p1 + d1 * r1, p1 + d0 * r1, n,
				Vector2(arc0, 0.0), Vector2(arc1, 0.0), Vector2(arc1, length), Vector2(arc0, length))
	if cap1 and r1 > 0.001:
		_tube_cap(cap_key, p1, dir, u_vec, w_vec, r1, sides)
	if cap0 and r0 > 0.001:
		_tube_cap(cap_key, p0, -dir, u_vec, w_vec, r0, sides)


func _tube_cap(key: String, center: Vector3, normal: Vector3, u_vec: Vector3, w_vec: Vector3, r: float, sides: int) -> void:
	for i in sides:
		var a0: float = TAU * float(i) / float(sides)
		var a1: float = TAU * float(i + 1) / float(sides)
		var d0: Vector3 = u_vec * cos(a0) + w_vec * sin(a0)
		var d1: Vector3 = u_vec * cos(a1) + w_vec * sin(a1)
		tri_flat(key, center, center + d0 * r, center + d1 * r, normal,
				Vector2(0.5, 0.5), Vector2(0.5, 0.5) + Vector2(cos(a0), sin(a0)) * r, Vector2(0.5, 0.5) + Vector2(cos(a1), sin(a1)) * r)


## Elipsoide fechado. As normais misturam a normal do próprio lóbulo com a "esférica" da copa
## (direção do centro da copa até o vértice): crown_mix 1 = só a da copa.
func blob(key: String, center: Vector3, radii: Vector3, sides: int, rings: int, crown_center: Vector3,
		crown_mix: float, turn: float = 0.0) -> void:
	var grid: Array = []
	for r in range(rings + 1):
		var phi: float = PI * float(r) / float(rings)
		var row: Array[Vector3] = []
		if r == 0 or r == rings:
			row.append(Vector3(0.0, -cos(phi), 0.0))
		else:
			for s in sides:
				var theta: float = turn + TAU * float(s) / float(sides) + (0.5 if r % 2 == 0 else 0.0) * TAU / float(sides)
				row.append(Vector3(sin(phi) * cos(theta), -cos(phi), sin(phi) * sin(theta)))
		grid.append(row)
	for r in range(rings):
		var lower: Array[Vector3] = grid[r]
		var upper: Array[Vector3] = grid[r + 1]
		var n_lo: int = lower.size()
		var n_up: int = upper.size()
		if n_lo == 1:
			for s in n_up:
				_blob_tri(key, center, radii, crown_center, crown_mix, lower[0], upper[s], upper[(s + 1) % n_up])
		elif n_up == 1:
			for s in n_lo:
				_blob_tri(key, center, radii, crown_center, crown_mix, lower[s], upper[0], lower[(s + 1) % n_lo])
		else:
			for s in n_lo:
				var s2: int = (s + 1) % n_lo
				_blob_tri(key, center, radii, crown_center, crown_mix, lower[s], upper[s], lower[s2])
				_blob_tri(key, center, radii, crown_center, crown_mix, lower[s2], upper[s], upper[s2])


func _blob_tri(key: String, center: Vector3, radii: Vector3, crown_center: Vector3, crown_mix: float,
		a: Vector3, b: Vector3, c: Vector3) -> void:
	var pts: Array[Vector3] = [center + a * radii, center + b * radii, center + c * radii]
	var normals: Array[Vector3] = []
	for i in 3:
		var unit: Vector3 = [a, b, c][i]
		var own: Vector3 = (unit / radii).normalized()
		var crown: Vector3 = (pts[i] - crown_center).normalized()
		normals.append(own.lerp(crown, crown_mix).normalized())
	tri(key, pts[0], pts[1], pts[2], normals[0], normals[1], normals[2])


## Sólido facetado (pedras): 3 anéis de `sides` pontos (multiplicadores de raio) e um ápice.
## rings = [[mult...] baixo, [mult...] meio, [mult...] alto]; alturas relativas fixas.
func faceted(key: String, center_xz: Vector2, half: Vector2, height: float, rings: Array, apex: Vector3, twist: float = 0.0) -> void:
	var ring_h: Array[float] = [0.0, 0.5, 0.88]
	var ring_r: Array[float] = [0.78, 1.0, 0.62]
	var pts: Array = []
	for r in 3:
		var mults: Array = rings[r]
		var row: Array[Vector3] = []
		for s in mults.size():
			var ang: float = twist + TAU * float(s) / float(mults.size()) + (0.18 if r == 1 else 0.0)
			var m: float = float(mults[s]) * ring_r[r]
			row.append(Vector3(center_xz.x + cos(ang) * half.x * m, height * ring_h[r], center_xz.y + sin(ang) * half.y * m))
		pts.append(row)
	var apex_pt := Vector3(center_xz.x + apex.x * half.x, height * apex.y, center_xz.y + apex.z * half.y)
	var mid := Vector3(center_xz.x, height * 0.45, center_xz.y)
	for r in 2:
		var lo: Array = pts[r]
		var hi: Array = pts[r + 1]
		var n_lo: int = lo.size()
		var n_hi: int = hi.size()
		# Os anéis têm o mesmo número de pontos: faixa de dois triângulos por face.
		for s in mini(n_lo, n_hi):
			var s2: int = (s + 1) % n_lo
			_facet(key, lo[s], hi[s], lo[s2], mid)
			_facet(key, lo[s2], hi[s], hi[s2], mid)
	var top_row: Array = pts[2]
	for s in top_row.size():
		_facet(key, top_row[s], apex_pt, top_row[(s + 1) % top_row.size()], mid)
	var base_row: Array = pts[0]
	for s in base_row.size():
		var p0: Vector3 = base_row[s]
		var p1: Vector3 = base_row[(s + 1) % base_row.size()]
		tri_flat(key, Vector3(center_xz.x, 0.0, center_xz.y), p0, p1, Vector3.DOWN)


func _facet(key: String, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	if n.dot((a + b + c) / 3.0 - inside) < 0.0:
		n = -n
	tri_flat(key, a, b, c, n)


## Grava os lotes numa ArrayMesh, uma superfície por material (ordem alfabética, estável).
func to_mesh(materials: Dictionary, tangent_keys: Dictionary) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var keys: Array = batches.keys()
	keys.sort()
	for key: String in keys:
		(batches[key] as MeshBatch).commit(mesh, materials[key] as Material, bool(tangent_keys.get(key, false)))
	return mesh

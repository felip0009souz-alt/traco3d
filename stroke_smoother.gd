class_name StrokeSmoother
extends RefCounted
## Suaviza uma lista de pontos 3D: relaxamento (tira tremor) + Catmull-Rom (curva).


static func smooth(points: PackedVector3Array, passes: int = 2, subdiv: int = 4) -> PackedVector3Array:
	var p: PackedVector3Array = points
	for _k in passes:
		p = _relax(p)
	return catmull_rom(p, subdiv)


# Média ponderada com os vizinhos; as pontas ficam fixas.
static func _relax(pts: PackedVector3Array) -> PackedVector3Array:
	var n := pts.size()
	if n < 3:
		return pts
	var out: PackedVector3Array = pts.duplicate()
	for i in range(1, n - 1):
		out[i] = pts[i - 1] * 0.25 + pts[i] * 0.5 + pts[i + 1] * 0.25
	return out


static func catmull_rom(pts: PackedVector3Array, subdiv: int = 4) -> PackedVector3Array:
	var n := pts.size()
	if n < 3:
		return pts
	var out := PackedVector3Array()
	for i in range(n - 1):
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, n - 1)]
		for s in subdiv:
			var t := float(s) / float(subdiv)
			out.append(p1.cubic_interpolate(p2, p0, p3, t))
	out.append(pts[n - 1])
	return out

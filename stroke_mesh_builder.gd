class_name StrokeMeshBuilder
extends RefCounted
## Transforma uma polilinha 3D em um tubo (malha), usando "parallel transport"
## para o tubo não torcer nas curvas.


static func build(points: PackedVector3Array, radius: float, sides: int = 8) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var n := points.size()
	if n < 2:
		return mesh

	# Tangentes em cada ponto
	var tangents: Array[Vector3] = []
	for i in n:
		var t: Vector3
		if i == 0:
			t = points[1] - points[0]
		elif i == n - 1:
			t = points[n - 1] - points[n - 2]
		else:
			t = points[i + 1] - points[i - 1]
		if t.length_squared() < 1e-12:
			t = tangents[i - 1] if i > 0 else Vector3.FORWARD
		tangents.append(t.normalized())

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	# Vetor normal inicial perpendicular à primeira tangente
	var ref := Vector3.UP
	if absf(tangents[0].dot(ref)) > 0.99:
		ref = Vector3.RIGHT
	var normal := tangents[0].cross(ref).normalized()

	for i in n:
		if i > 0:
			var axis := tangents[i - 1].cross(tangents[i])
			if axis.length_squared() > 1e-10:
				normal = normal.rotated(axis.normalized(), tangents[i - 1].angle_to(tangents[i]))
		normal = (normal - tangents[i] * normal.dot(tangents[i])).normalized()
		var binormal := tangents[i].cross(normal)
		for s in sides:
			var a := TAU * float(s) / float(sides)
			var dir := normal * cos(a) + binormal * sin(a)
			verts.append(points[i] + dir * radius)
			normals.append(dir)

	# Corpo do tubo
	for i in range(n - 1):
		for s in sides:
			var s2 := (s + 1) % sides
			var a := i * sides + s
			var b := i * sides + s2
			var c := (i + 1) * sides + s
			var d := (i + 1) * sides + s2
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))

	# Tampas nas duas pontas
	var start_center := verts.size()
	verts.append(points[0])
	normals.append(-tangents[0])
	for s in sides:
		indices.append_array(PackedInt32Array([start_center, (s + 1) % sides, s]))
	var end_center := verts.size()
	verts.append(points[n - 1])
	normals.append(tangents[n - 1])
	var last_ring := (n - 1) * sides
	for s in sides:
		indices.append_array(PackedInt32Array([end_center, last_ring + s, last_ring + (s + 1) % sides]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

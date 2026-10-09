class_name Stroke
extends MeshInstance3D
## Um traço 3D. Guarda os pontos originais (raw_points) e gera a malha suavizada.
## Mais tarde: salvar/carregar, selecionar e transformar partem daqui.

var raw_points := PackedVector3Array()
var radius := 0.02
var color := Color("#8B7CFF")


func _init() -> void:
	var m := StandardMaterial3D.new()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.45
	material_override = m


func set_color(c: Color) -> void:
	color = c
	(material_override as StandardMaterial3D).albedo_color = c


func rebuild() -> void:
	var smooth := StrokeSmoother.smooth(raw_points)
	mesh = StrokeMeshBuilder.build(smooth, radius)

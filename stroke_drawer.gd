class_name StrokeDrawer
extends Node3D
## Converte toques na tela em pontos 3D e cria os traços.
## Cada traço é desenhado em um plano perpendicular à câmera, passando pelo
## ponto que a câmera está olhando (o "alvo" da órbita).

@export var min_pixel_distance := 4.0   # distância mínima entre pontos (px)
@export var width_factor := 0.006       # espessura = distância da câmera * fator

var rig: OrbitCamera
var stroke_color := Color("#8B7CFF")
var strokes: Array[Stroke] = []

var _current: Stroke
var _plane: Plane
var _last_screen := Vector2.ZERO
var _dirty := false


func begin(screen_pos: Vector2) -> void:
	if _current != null:
		end()
	var cam := rig.camera
	var forward := -cam.global_transform.basis.z
	_plane = Plane(forward, rig.global_position)

	_current = Stroke.new()
	_current.radius = rig.distance * width_factor
	add_child(_current)
	_current.set_color(stroke_color)

	var p := _project(screen_pos)
	if p != Vector3.INF:
		_current.raw_points.append(p)
	_last_screen = screen_pos


func extend(screen_pos: Vector2) -> void:
	if _current == null:
		return
	if screen_pos.distance_to(_last_screen) < min_pixel_distance:
		return
	var p := _project(screen_pos)
	if p == Vector3.INF:
		return
	_current.raw_points.append(p)
	_last_screen = screen_pos
	_dirty = true


## Finaliza o traço. Se tiver poucos pontos, descarta.
func end(min_points: int = 2) -> void:
	if _current == null:
		return
	if _current.raw_points.size() < min_points:
		_current.queue_free()
	else:
		_current.rebuild()
		strokes.append(_current)
	_current = null
	_dirty = false


func undo_last() -> void:
	if strokes.is_empty():
		return
	strokes.pop_back().queue_free()


func _process(_delta: float) -> void:
	# Reconstrói a malha no máximo uma vez por frame
	if _dirty and _current != null:
		_current.rebuild()
		_dirty = false


func _project(screen_pos: Vector2) -> Vector3:
	var cam := rig.camera
	var origin := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	var hit: Variant = _plane.intersects_ray(origin, dir)
	if hit == null:
		return Vector3.INF
	return hit

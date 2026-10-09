class_name OrbitCamera
extends Node3D
## Câmera orbital: este nó fica no ponto-alvo; a Camera3D filha fica "para trás".

var camera: Camera3D
var yaw := 0.4
var pitch := -0.35
var distance := 3.0

const MIN_DISTANCE := 0.3
const MAX_DISTANCE := 20.0
const HOME_TARGET := Vector3(0, 0.6, 0)


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 60.0
	camera.near = 0.05
	camera.far = 100.0
	add_child(camera)
	camera.current = true
	reset()


func reset() -> void:
	position = HOME_TARGET
	yaw = 0.4
	pitch = -0.35
	distance = 3.0
	_apply()


func orbit(delta_px: Vector2) -> void:
	yaw -= delta_px.x * 0.006
	pitch = clampf(pitch - delta_px.y * 0.006, -1.5, 1.5)
	_apply()


func pan(delta_px: Vector2) -> void:
	var h := get_viewport().get_visible_rect().size.y
	var per_px := 2.0 * tan(deg_to_rad(camera.fov) * 0.5) * distance / h
	var b := camera.global_transform.basis
	position += (-b.x * delta_px.x + b.y * delta_px.y) * per_px
	_apply()


## factor > 1 aproxima, factor < 1 afasta.
func zoom(factor: float) -> void:
	distance = clampf(distance / factor, MIN_DISTANCE, MAX_DISTANCE)
	_apply()


func _apply() -> void:
	rotation = Vector3(pitch, yaw, 0.0)
	camera.position = Vector3(0, 0, distance)

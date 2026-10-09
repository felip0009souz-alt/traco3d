class_name TouchController
extends Node
## Interpreta os gestos:
##   1 dedo  -> desenha
##   2 dedos -> gira (ou move) a câmera e faz zoom com o pinch
## No PC (para testar): botão esquerdo desenha, direito gira,
## do meio move, roda do mouse dá zoom.

const DEVICE_EMULATION := -1   # mouse emulado a partir de toque

var rig: OrbitCamera
var drawer: StrokeDrawer
var ui_blockers: Array[Control] = []
var two_finger_pan := false   # false = girar, true = mover

var _touches := {}            # índice do toque -> posição
var _drawing_touch := -1
var _mouse_drawing := false
var _prev_centroid := Vector2.ZERO
var _prev_dist := 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_on_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event as InputEventMouseMotion)


func _is_over_ui(pos: Vector2) -> bool:
	for c in ui_blockers:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


# ---------- Toque ----------

func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		if _is_over_ui(e.position):
			return
		_touches[e.index] = e.position
		if _touches.size() == 1:
			_drawing_touch = e.index
			drawer.begin(e.position)
		elif _touches.size() == 2:
			if _drawing_touch != -1:
				drawer.end(6)   # descarta se foi só o início de um gesto de 2 dedos
				_drawing_touch = -1
			_reset_gesture_baseline()
	else:
		if not _touches.has(e.index):
			return
		_touches.erase(e.index)
		if e.index == _drawing_touch:
			drawer.end()
			_drawing_touch = -1
		if _touches.size() >= 2:
			_reset_gesture_baseline()


func _on_drag(e: InputEventScreenDrag) -> void:
	if not _touches.has(e.index):
		return
	_touches[e.index] = e.position
	if _touches.size() >= 2:
		_update_gesture()
	elif e.index == _drawing_touch:
		drawer.extend(e.position)


func _two_points() -> Array[Vector2]:
	var keys := _touches.keys()
	var out: Array[Vector2] = []
	out.append(_touches[keys[0]])
	out.append(_touches[keys[1]])
	return out


func _reset_gesture_baseline() -> void:
	var pts := _two_points()
	_prev_centroid = (pts[0] + pts[1]) * 0.5
	_prev_dist = pts[0].distance_to(pts[1])


func _update_gesture() -> void:
	var pts := _two_points()
	var centroid := (pts[0] + pts[1]) * 0.5
	var dist := pts[0].distance_to(pts[1])
	if _prev_dist > 1.0 and dist > 1.0:
		rig.zoom(dist / _prev_dist)
	var d := centroid - _prev_centroid
	if two_finger_pan:
		rig.pan(d)
	else:
		rig.orbit(d)
	_prev_centroid = centroid
	_prev_dist = dist


# ---------- Mouse (testes no PC) ----------

func _on_mouse_button(e: InputEventMouseButton) -> void:
	if e.device == DEVICE_EMULATION:
		return   # mouse emulado a partir do toque: já tratamos o toque
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			if e.pressed:
				if _is_over_ui(e.position):
					return
				_mouse_drawing = true
				drawer.begin(e.position)
			elif _mouse_drawing:
				_mouse_drawing = false
				drawer.end()
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
				rig.zoom(1.1)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				rig.zoom(1.0 / 1.1)


func _on_mouse_motion(e: InputEventMouseMotion) -> void:
	if e.device == DEVICE_EMULATION:
		return
	if _mouse_drawing:
		drawer.extend(e.position)
	elif e.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		rig.orbit(e.relative)
	elif e.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		rig.pan(e.relative)

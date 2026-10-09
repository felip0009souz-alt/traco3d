extends Node3D
## Monta a cena inteira por código (ambiente, câmera, grade, interface).

var rig: OrbitCamera
var drawer: StrokeDrawer
var touch: TouchController
var _mode_button: Button


func _ready() -> void:
	_build_environment()

	rig = OrbitCamera.new()
	add_child(rig)

	# Luz presa à câmera: o traço fica iluminado de qualquer ângulo
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, 25, 0)
	light.light_energy = 1.0
	rig.camera.add_child(light)

	drawer = StrokeDrawer.new()
	drawer.rig = rig
	add_child(drawer)

	touch = TouchController.new()
	touch.rig = rig
	touch.drawer = drawer
	add_child(touch)

	_build_ui()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#14141C")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.85)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	add_child(_make_grid())


func _make_grid() -> MeshInstance3D:
	var half := 2.0
	var step := 0.25
	var n := int(half / step)
	var verts := PackedVector3Array()
	for i in range(-n, n + 1):
		var t := i * step
		verts.append(Vector3(t, 0, -half))
		verts.append(Vector3(t, 0, half))
		verts.append(Vector3(-half, 0, t))
		verts.append(Vector3(half, 0, t))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.12)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi


# ---------- Interface ----------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := MarginContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 40)
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.09, 0.13, 0.85)
	sb.set_corner_radius_all(40)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)
	touch.ui_blockers.append(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var undo := _make_button("Desfazer")
	undo.pressed.connect(func(): drawer.undo_last())
	row.add_child(undo)

	_mode_button = _make_button("2 dedos: Girar")
	_mode_button.pressed.connect(_toggle_mode)
	row.add_child(_mode_button)

	var home := _make_button("Centralizar")
	home.pressed.connect(func(): rig.reset())
	row.add_child(home)


func _toggle_mode() -> void:
	touch.two_finger_pan = not touch.two_finger_pan
	_mode_button.text = "2 dedos: Mover" if touch.two_finger_pan else "2 dedos: Girar"


func _make_button(label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 96)
	b.add_theme_font_size_override("font_size", 32)
	b.add_theme_color_override("font_color", Color("#E8E6FF"))
	b.add_theme_stylebox_override("normal", _btn_style(Color(1, 1, 1, 0.07)))
	b.add_theme_stylebox_override("hover", _btn_style(Color(1, 1, 1, 0.12)))
	b.add_theme_stylebox_override("pressed", _btn_style(Color("#8B7CFF")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _btn_style(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(28)
	s.content_margin_left = 28
	s.content_margin_right = 28
	return s

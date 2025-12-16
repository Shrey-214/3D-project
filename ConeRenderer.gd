extends MeshInstance3D
class_name ConeRenderer

@export var points: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -2)]  
@export var start_radius: float = 0.008
@export var end_radius: float = 0.06
@export_range(3, 128, 1) var slices: int = 24
@export var cap_tip: bool = false
@export var global_coords: bool = true
@export var color: Color = Color(1, 1, 1, 0.28)

var _im: ImmediateMesh

func _ready() -> void:
	
	if mesh == null or not (mesh is ImmediateMesh):
		_im = ImmediateMesh.new()
		mesh = _im
	else:
		_im = mesh as ImmediateMesh

	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = color
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = false
	material_override = mat

func _process(_dt: float) -> void:
	if points.size() < 2:
		return

	var A: Vector3 = points[0]
	var B: Vector3 = points[1]
	if global_coords:
		A = to_local(A)
		B = to_local(B)

	var axis: Vector3 = B - A
	var len: float = axis.length()
	if len < 1e-5:
		_im.clear_surfaces()
		return

	var t: Vector3 = axis / len

	
	var up: Vector3 = Vector3.UP
	if abs(t.dot(Vector3.UP)) > 0.95:
		up = Vector3.RIGHT
	var u: Vector3 = t.cross(up).normalized()
	var v: Vector3 = t.cross(u).normalized()

	var r0: float = max(start_radius, 0.0005)
	var r1: float = max(end_radius,   0.0005)
	var step: float = TAU / float(max(3, slices))

	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material_override)

	
	for i in range(slices):
		var a0: float = step * float(i)
		var a1: float = step * float(i + 1)

		var c0: Vector3 = u * cos(a0) + v * sin(a0)
		var c1: Vector3 = u * cos(a1) + v * sin(a1)

		var a_near: Vector3 = A + c0 * r0
		var b_near: Vector3 = A + c1 * r0
		var a_far:  Vector3 = B + c0 * r1
		var b_far:  Vector3 = B + c1 * r1

		_im.surface_set_color(color)
		_im.surface_add_vertex(a_near); _im.surface_add_vertex(a_far); _im.surface_add_vertex(b_far)
		_im.surface_set_color(color)
		_im.surface_add_vertex(a_near); _im.surface_add_vertex(b_far); _im.surface_add_vertex(b_near)

	
	if cap_tip:
		for i in range(slices):
			var a0c: float = step * float(i)
			var a1c: float = step * float(i + 1)
			var c0c: Vector3 = u * cos(a0c) + v * sin(a0c)
			var c1c: Vector3 = u * cos(a1c) + v * sin(a1c)
			var p0: Vector3 = B + c0c * r1
			var p1: Vector3 = B + c1c * r1
			_im.surface_set_color(color)
			_im.surface_add_vertex(B); _im.surface_add_vertex(p1); _im.surface_add_vertex(p0)

	_im.surface_end()

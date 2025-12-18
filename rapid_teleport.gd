extends XROrigin3D

@export var teleport_speed: float = 8.0
@export var max_teleport_distance: float = 12.0
@export var arrive_threshold: float = 0.08

@export_node_path("RayCast3D") var teleport_ray_path: NodePath
@export_node_path("Node3D") var teleport_marker_path: NodePath
@export_node_path("XRController3D") var right_controller_path: NodePath

var _enabled := false
var _is_teleporting := false
var _target_pos: Vector3
var _trigger_was_down := false

@onready var teleport_ray: RayCast3D = get_node_or_null(teleport_ray_path)
@onready var teleport_marker: Node3D = get_node_or_null(teleport_marker_path)
@onready var right_controller: XRController3D = get_node_or_null(right_controller_path)

func set_enabled(v: bool) -> void:
	_enabled = v
	_is_teleporting = false
	if teleport_marker:
		teleport_marker.visible = false
	print("[RapidTP] enabled = ", _enabled)

func _process(delta: float) -> void:
	if not _enabled:
		return
	if teleport_ray == null or teleport_marker == null or right_controller == null:
		return

	if _is_teleporting:
		_update_teleport(delta)
	else:
		_update_pointer()

	_handle_trigger()

func _update_pointer() -> void:
	if not teleport_ray.is_colliding():
		teleport_marker.visible = false
		return

	var hit_point := teleport_ray.get_collision_point()
	var dist := global_transform.origin.distance_to(hit_point)
	if dist > max_teleport_distance:
		teleport_marker.visible = false
		return

	teleport_marker.global_transform.origin = hit_point
	teleport_marker.visible = true

func _handle_trigger() -> void:
	var trigger_down := right_controller.get_float(&"trigger") > 0.8
	if trigger_down and not _trigger_was_down:
		_start_teleport()
	_trigger_was_down = trigger_down

func _start_teleport() -> void:
	if teleport_marker == null or not teleport_marker.visible:
		print("[RapidTP] no valid target")
		return
	_target_pos = teleport_marker.global_transform.origin
	_is_teleporting = true
	teleport_marker.visible = false
	print("[RapidTP] start -> ", _target_pos)

func _update_teleport(delta: float) -> void:
	var current := global_transform.origin
	var dir := _target_pos - current
	dir.y = 0.0

	var dist := dir.length()
	if dist <= arrive_threshold:
		var t := global_transform
		t.origin.x = _target_pos.x
		t.origin.z = _target_pos.z
		global_transform = t
		_is_teleporting = false
		print("[RapidTP] arrived")
		return

	var step := dir.normalized() * teleport_speed * delta
	if step.length() > dist:
		step = dir

	var t2 := global_transform
	t2.origin += step
	global_transform = t2

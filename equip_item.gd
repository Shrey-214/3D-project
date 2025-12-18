extends Area3D

@export var value: int = 1

# ✅ Hand placement controls (edit per object in Inspector)
@export var hold_offset: Vector3 = Vector3(0.0, -0.05, -0.18)
@export var hold_rotation_deg: Vector3 = Vector3(0.0, 90.0, 0.0)
@export var hold_scale: float = 0.15

var collected := false
var held := false
var holder: XRController3D = null
var _prev_trigger_down := false

func _ready() -> void:
	add_to_group("equip")
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	set_process(true)
	print("[Equip READY]", name)

func _on_area_entered(area: Area3D) -> void:
	if collected or held:
		return
	if area != null and area.is_in_group("hand"):
		var controller := area.get_parent() as XRController3D
		if controller:
			_attach_to_controller(controller)

func _attach_to_controller(controller: XRController3D) -> void:
	holder = controller
	held = true

	# ✅ ROOT is the MeshInstance3D (parent of this Area3D)
	var root := get_parent() as Node3D
	if root == null:
		print("[Equip] ERROR: Area has no Node3D parent root")
		return

	# ✅ Reparent ROOT to controller so mesh + collision move together
	var old_parent := root.get_parent()
	if old_parent:
		old_parent.remove_child(root)
	controller.add_child(root)

	# ✅ Apply hand pose: offset + rotation + scale
	root.position = hold_offset
	root.rotation_degrees = hold_rotation_deg
	root.scale = Vector3.ONE * hold_scale

	# Keep collisions disabled while held (optional)
	monitoring = false
	monitorable = false

	print("[Equip] Attached:", root.name, "->", controller.name,
		" | scale=", hold_scale, " rot=", hold_rotation_deg, " offset=", hold_offset)

func _process(_delta: float) -> void:
	if not held or holder == null or collected:
		return

	var trigger_down := holder.get_float(&"trigger") > 0.8
	if trigger_down and not _prev_trigger_down:
		_collect()
	_prev_trigger_down = trigger_down

func _collect() -> void:
	if collected:
		return
	collected = true

	# notify player
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_equipment"):
		player.call("add_equipment", value)

	
	var root := get_parent()
	if root:
		root.queue_free()
	else:
		queue_free()

	print("[Equip] Collected -> removed")

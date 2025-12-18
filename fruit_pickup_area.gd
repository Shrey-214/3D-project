extends Area3D

@export var hold_offset: Vector3 = Vector3(0, 0, -0.25)

var held: bool = false
var holder: XRController3D = null
var _original_parent: Node = null
var _original_global: Transform3D

func _ready() -> void:
	add_to_group("fruit")
	monitoring = true
	monitorable = true
	print("[FruitArea] READY: ", name)

func pick_up_to_controller(controller: XRController3D) -> bool:
	if held:
		print("[Fruit] Already held")
		return false
	if controller == null:
		print("[Fruit] Controller null")
		return false

	held = true
	holder = controller

	_original_parent = get_parent()
	_original_global = global_transform

	
	if _original_parent:
		_original_parent.remove_child(self)
	controller.add_child(self)

	
	transform = Transform3D.IDENTITY.translated(hold_offset)

	monitoring = false
	print("[Fruit] Picked up by ", controller.name)
	return true

func drop_from_controller() -> void:
	if not held:
		return

	held = false
	monitoring = true

	var world_xform := global_transform

	
	if holder:
		holder.remove_child(self)
	if _original_parent:
		_original_parent.add_child(self)

	global_transform = world_xform
	holder = null

	print("[Fruit] Dropped")

func consume() -> void:
	print("[Fruit] Consumed -> queue_free")
	queue_free()

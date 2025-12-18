extends Area3D

@export var value: int = 1

var collected: bool = false
var held: bool = false
var holder: XRController3D = null
var _prev_trigger_down: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true

	print("[Ore READY] ", name,
		" monitoring=", monitoring,
		" monitorable=", monitorable,
		" layer=", collision_layer,
		" mask=", collision_mask)

	# ✨ listen to both areas and bodies
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	set_process(true)


# -------------------------------------------------
# HAND touches ore → attach to that controller
# -------------------------------------------------
func _on_area_entered(area: Area3D) -> void:
	print("[Ore] area_entered from: ", area.name, " groups=", area.get_groups())

	if collected or held:
		return

	if area.is_in_group("hand"):
		var controller := area.get_parent() as XRController3D
		if controller:
			_attach_to_controller(controller)
		else:
			print("[Ore] Hand Area parent is not an XRController3D")


# -------------------------------------------------
# (Optional) PLAYER BODY hits ore → attach to right hand
# You can remove this whole function if you *only* want hands.
# -------------------------------------------------
func _on_body_entered(body: Node3D) -> void:
	print("[Ore] body_entered from: ", body.name, " groups=", body.get_groups())

	if collected or held:
		return

	if body.is_in_group("player"):
		var rc := body.get_node_or_null("XROrigin3D/RightController") as XRController3D
		if rc:
			_attach_to_controller(rc)
		else:
			print("[Ore] Could not find RightController under player!")


# -------------------------------------------------
# Attach ore under a controller node
# -------------------------------------------------
func _attach_to_controller(controller: XRController3D) -> void:
	holder = controller
	held = true
	print("[Ore] Attached to controller: ", controller.name)

	# Re-parent so it follows the hand
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)

	# Put the ore a bit in front of the controller in local space
	transform = Transform3D.IDENTITY.translated(Vector3(0, 0, -0.15))

	# Stop further physics triggers while held
	monitoring = false


# -------------------------------------------------
# While held → watch trigger, collect on press
# -------------------------------------------------
func _process(delta: float) -> void:
	if not held or holder == null or collected:
		return

	var trigger_value := holder.get_float(&"trigger")

	if trigger_value == 0.0:
		trigger_value = holder.get_float(&"trigger_value")

	if Input.is_action_pressed("ui_accept"):
		trigger_value = 1.0

	var trigger_down := trigger_value > 0.8

	if trigger_down and not _prev_trigger_down:
		print("[Ore] Trigger pressed while held (value =", trigger_value, "), collecting…")
		_collect()

	_prev_trigger_down = trigger_down


# -------------------------------------------------
# Collect & notify player
# -------------------------------------------------
func _collect() -> void:
	if collected:
		return
	collected = true

	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_ore"):
		player.add_ore(value)
		print("[Ore] Told player to add_ore(", value, ")")
	else:
		print("[Ore] Player not found or add_ore() missing")

	queue_free()

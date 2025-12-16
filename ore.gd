## res://ore.gd
#extends Area3D
#
#@export var value: int = 1
#var collected: bool = false
#
#func collect() -> void:
	#if collected:
		#return
	#collected = true
#
	## Find the player and increment the ore count
	#var player := get_tree().get_first_node_in_group("player")
	#if player and player.has_method("add_ore"):
		#player.add_ore(value)
#
	## TODO: you can play a sound or particle here if you like
#
	#queue_free()  # remove the ore from the scene





#extends Area3D
#
#@export var value: int = 1
#var collected: bool = false
#
#func _ready() -> void:
	#monitoring = true
	#monitorable = true
#
	## Debug so we can see config is correct
	#print("[Ore READY] ", name,
		#" monitoring=", monitoring,
		#" monitorable=", monitorable,
		#" layer=", collision_layer,
		#" mask=", collision_mask)
#
	#area_entered.connect(_on_area_entered)
	#body_entered.connect(_on_body_entered)
#
#func _on_area_entered(area: Area3D) -> void:
	#print("[Ore] area_entered from: ", area.name,
		#" groups=", area.get_groups())
#
	#if collected:
		#return
#
	## If a hand Area3D touches us, collect
	#if area.is_in_group("hand"):
		#print("[Ore] HAND area touched me, collecting…")
		#_collect()
#
#func _on_body_entered(body: Node3D) -> void:
	## This is already firing (we saw it in your log)
	#print("[Ore] body_entered from: ", body.name,
		#" groups=", body.get_groups())
#
	#if collected:
		#return
#
	## If the player body walks into the ore, collect as well
	#if body.is_in_group("player"):
		#print("[Ore] PLAYER body touched me, collecting…")
		#_collect()
#
#func _collect() -> void:
	#if collected:
		#return
	#collected = true
#
	#var player := get_tree().get_first_node_in_group("player")
	#if player and player.has_method("add_ore"):
		#player.add_ore(value)
		#print("[Ore] Told player to add_ore(", value, ")")
	#else:
		#print("[Ore] Player not found or add_ore() missing")
#
	#queue_free()


















#extends Area3D
#
#@export var value: int = 1
#
#var collected: bool = false
#var held: bool = false
#var holder: XRController3D = null
#var _prev_trigger_down: bool = false
#
#func _ready() -> void:
	#monitoring = true
	#monitorable = true
#
	## Debug so we see that the ore is configured
	#print("[Ore READY] ", name,
		#" monitoring=", monitoring,
		#" monitorable=", monitorable,
		#" layer=", collision_layer,
		#" mask=", collision_mask)
#
	#body_entered.connect(_on_body_entered)
	#set_process(true)
#
#
## -------------------------------------------------
## When the PLAYER body hits the ore → attach to hand
## -------------------------------------------------
#func _on_body_entered(body: Node3D) -> void:
	#print("[Ore] body_entered from: ", body.name, " groups=", body.get_groups())
#
	#if collected or held:
		#return
#
	#if body.is_in_group("player"):
		#_attach_to_player(body as CharacterBody3D)
#
#
#func _attach_to_player(player: CharacterBody3D) -> void:
	## Find the right controller under the player
	#var rc := player.get_node_or_null("XROrigin3D/RightController") as XRController3D
	#if rc == null:
		#print("[Ore] Could not find RightController under player!")
		#return
#
	#holder = rc
	#held = true
	#print("[Ore] Attached to RightController")
#
	## Re-parent under the controller so it moves with the hand
	#var old_parent := get_parent()
	#if old_parent:
		#old_parent.remove_child(self)
	#rc.add_child(self)
#
	## Put the ore a bit in front of the controller
	#transform = Transform3D.IDENTITY.translated(Vector3(0, 0, -0.15))
#
	## No longer need physics monitoring while held
	#monitoring = false
#
#
## -------------------------------------------------
## While held → watch trigger, collect on press
## -------------------------------------------------
#func _process(delta: float) -> void:
	#if not held or holder == null or collected:
		#return
#
	## Try reading trigger axis from XR controller directly
	#var trigger_value := holder.get_float(&"trigger")
#
	## Fallback: some action maps use "trigger_value" instead
	#if trigger_value == 0.0:
		#trigger_value = holder.get_float(&"trigger_value")
#
	## Editor / keyboard fallback: space/Enter
	#if Input.is_action_pressed("ui_accept"):
		#trigger_value = 1.0
#
	#var trigger_down := trigger_value > 0.8
#
	## Rising edge = trigger was just pressed
	#if trigger_down and not _prev_trigger_down:
		#print("[Ore] Trigger pressed while held (value =", trigger_value, "), collecting…")
		#_collect()
#
	#_prev_trigger_down = trigger_down
#
#
#
## -------------------------------------------------
## Collect & notify player
## -------------------------------------------------
#func _collect() -> void:
	#if collected:
		#return
	#collected = true
#
	#var player := get_tree().get_first_node_in_group("player")
	#if player and player.has_method("add_ore"):
		#player.add_ore(value)
		#print("[Ore] Told player to add_ore(", value, ")")
	#else:
		#print("[Ore] Player not found or add_ore() missing")
#
	#queue_free()


































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

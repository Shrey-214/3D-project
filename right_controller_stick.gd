#extends XRController3D
#
#@export var stick_length: float = 6.0
#@export var collision_mask: int = 0xFFFFFFFF
#@export var debug_print_hits: bool = true
#
#@onready var stick_visual: MeshInstance3D = $StickVisual
#
#var _enabled: bool = false
#var _last_hit: Object = null
#
#var held_fruit_area: Area3D = null
#var _trigger_was_down: bool = false
#
#func set_enabled(v: bool) -> void:
	#_enabled = v
	#if stick_visual:
		#stick_visual.visible = v
#
#func _ready() -> void:
	#set_enabled(false)
#
#func _physics_process(_delta: float) -> void:
	#if not _enabled or stick_visual == null:
		#return
#
	#var origin: Vector3 = global_transform.origin
	#var end: Vector3 = origin + (-global_transform.basis.z) * stick_length
#
	## stick default full length
	#stick_visual.points[0] = origin
	#stick_visual.points[1] = end
#
	## ray query (no RayCast3D node)
	#var params := PhysicsRayQueryParameters3D.create(origin, end)
	#params.collide_with_areas = true
	#params.collide_with_bodies = true
	#params.collision_mask = collision_mask
#
	#var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(params)
#
	#var hit_area: Area3D = null
#
	#if result.size() > 0:
		#var hit_pos: Vector3 = result["position"]
		#var collider: Object = result["collider"]
#
		## shorten stick
		#stick_visual.points[1] = hit_pos
#
		## debug print when collider changes
		#if debug_print_hits and collider != _last_hit and collider != null:
			#_last_hit = collider
			#if collider is Node:
				#print("[Stick] collision with: ", (collider as Node).name)
			#else:
				#print("[Stick] collision with: ", collider)
#
		## if collider is an Area3D and is fruit, remember it
		#if collider is Area3D and (collider as Area3D).is_in_group("fruit"):
			#hit_area = collider as Area3D
	#else:
		#_last_hit = null
#
	## trigger edge detect
	#var trigger_value := get_float(&"trigger")
	#var trigger_down := trigger_value > 0.8
	#if trigger_down and not _trigger_was_down:
		#_on_trigger_pressed(hit_area)
	#_trigger_was_down = trigger_down
#
#func _on_trigger_pressed(hit_fruit_area: Area3D) -> void:
	## If already holding fruit -> drop it (optional)
	#if held_fruit_area != null:
		#if held_fruit_area.has_method("drop_from_controller"):
			#held_fruit_area.call("drop_from_controller")
		#print("[Stick] Dropped fruit")
		#held_fruit_area = null
		#return
#
	## Not holding -> try pick fruit
	#if hit_fruit_area == null:
		#print("[Stick] Trigger pressed but not pointing at fruit")
		#return
#
	#if hit_fruit_area.has_method("pick_up_to_controller"):
		#var ok: bool = bool(hit_fruit_area.call("pick_up_to_controller", self))
		#print("[Stick] Pick fruit result = ", ok)
		#if ok:
			#held_fruit_area = hit_fruit_area

extends XRController3D

@export var stick_length: float = 6.0
@export var collision_mask: int = 0xFFFFFFFF
@export var debug_print_hits: bool = true

# IMPORTANT: how close the fruit must be to the animal to count as "feeding"
@export var feed_distance: float = 0.6

@onready var stick_visual: MeshInstance3D = $StickVisual

var _enabled: bool = false
var _last_hit: Object = null

var held_fruit_root: Node3D = null
var _trigger_was_down: bool = false

# where the fruit sits when held
const HOLD_OFFSET := Vector3(0, 0, -0.35)

func set_enabled(v: bool) -> void:
	_enabled = v
	if stick_visual:
		stick_visual.visible = v

func _ready() -> void:
	set_enabled(false)

func _physics_process(_delta: float) -> void:
	if not _enabled or stick_visual == null:
		return

	var origin: Vector3 = global_transform.origin
	var end: Vector3 = origin + (-global_transform.basis.z) * stick_length

	# default full length
	stick_visual.points[0] = origin
	stick_visual.points[1] = end

	# ray query (NO RayCast3D node)
	var params := PhysicsRayQueryParameters3D.create(origin, end)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = collision_mask

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(params)

	var hit_area: Area3D = null

	if not result.is_empty():
		var hit_pos: Vector3 = result["position"]
		var collider = result["collider"]

		# shorten stick
		stick_visual.points[1] = hit_pos

		# debug print when collider changes
		if debug_print_hits and collider != _last_hit and collider != null:
			_last_hit = collider
			if collider is Node:
				print("[Stick] collision with: ", (collider as Node).name)
			else:
				print("[Stick] collision with: ", collider)

		# if collider is fruit Area3D, remember it
		if collider is Area3D and (collider as Area3D).is_in_group("fruit"):
			hit_area = collider as Area3D
	else:
		_last_hit = null

	# trigger rising edge
	var trigger_down := get_float(&"trigger") > 0.8
	if trigger_down and not _trigger_was_down:
		_on_trigger_pressed(hit_area)
	_trigger_was_down = trigger_down


func _on_trigger_pressed(hit_fruit_area: Area3D) -> void:
	# If holding fruit -> first try FEED (only if close enough), else drop
	if held_fruit_root != null:
		if _try_feed_animal_close():
			return
		_drop_fruit()
		return

	# Not holding -> try pick fruit
	if hit_fruit_area == null:
		print("[Stick] Trigger pressed but not pointing at fruit")
		return

	_pick_fruit_from_area(hit_fruit_area)


func _pick_fruit_from_area(fruit_area: Area3D) -> void:
	# Expect:
	# BananaRoot (Node3D)
	#   ├ Banana (MeshInstance3D)
	#   └ Area3D (fruit)  <-- fruit_area
	var root := fruit_area.get_parent() as Node3D
	if root == null:
		print("[Stick] Fruit area has no Node3D parent")
		return

	held_fruit_root = root

	# move whole root so mesh + collision move together
	root.reparent(self, true)
	root.transform.origin = HOLD_OFFSET

	print("[Stick] Picked fruit root: ", root.name)


func _drop_fruit() -> void:
	if held_fruit_root == null:
		return

	var world_root := get_tree().current_scene
	held_fruit_root.reparent(world_root, true)

	print("[Stick] Dropped fruit: ", held_fruit_root.name)
	held_fruit_root = null


# ✅ Only feed if fruit is CLOSE to an animal Area3D
func _try_feed_animal_close() -> bool:
	if held_fruit_root == null:
		return false

	# Check distance against all animal Area3D nodes
	var animal_areas := get_tree().get_nodes_in_group("animal")
	for a in animal_areas:
		if a is Area3D:
			var animal_area := a as Area3D
			var d := held_fruit_root.global_transform.origin.distance_to(animal_area.global_transform.origin)

			if d <= feed_distance:
				print("[Feed] Fed animal (distance=", d, ") -> banana disappears")

				# remove banana root only
				held_fruit_root.queue_free()
				held_fruit_root = null

				# notify player score
				var player := get_tree().get_first_node_in_group("player")
				if player and player.has_method("on_animal_fed"):
					player.on_animal_fed()

				return true

	print("[Feed] Not close enough to animal yet")
	return false
